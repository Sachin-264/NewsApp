import SwiftUI
import CryptoKit
import ImageIO

enum ImageDecoder {
    static func decodeSafely(from data: Data, maxPixelSize: CGFloat = 1200) -> UIImage? {
        guard data.count > 200 else { return nil }

        let sourceOptions: [CFString: Any] = [
            kCGImageSourceShouldCache: true
        ]

        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions as CFDictionary) else {
            return UIImage(data: data)
        }

        guard CGImageSourceGetCount(source) > 0 else {
            return UIImage(data: data)
        }

        let thumbnailOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ]

        if let cgThumb = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions as CFDictionary) {
            guard cgThumb.width > 1 && cgThumb.height > 1 else { return nil }
            return UIImage(cgImage: cgThumb)
        }

        return UIImage(data: data)
    }
}

enum ImageURLHelper {
    static func sanitize(urlString: String) -> String {
        var clean = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.lowercased().hasPrefix("http://") {
            clean = "https://" + clean.dropFirst("http://".count)
        }
        return clean
    }
}

enum ImageProxyHelper {
    static func proxyURL(for urlString: String) -> URL? {
        let sanitized = ImageURLHelper.sanitize(urlString: urlString)
        guard let encoded = sanitized.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return nil }
        return URL(string: "https://images.weserv.nl/?url=\(encoded)&w=1200&output=jpg")
    }
}

final class ImageCache {
    static let shared = ImageCache()
    private let memoryCache = NSCache<NSURL, UIImage>()
    private let fileManager = FileManager.default
    private let diskCacheURL: URL
    private let diskQueue = DispatchQueue(label: "com.newsapp.imagecache.disk", qos: .background)
    private let queueKey = DispatchSpecificKey<Void>()

    private init() {
        diskQueue.setSpecific(key: queueKey, value: ())

        memoryCache.countLimit = 200
        memoryCache.totalCostLimit = 1024 * 1024 * 100

        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        diskCacheURL = cachesDirectory.appendingPathComponent("NewsAppImageCache", isDirectory: true)

        if !fileManager.fileExists(atPath: diskCacheURL.path) {
            try? fileManager.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
        }
    }

    private func performOnDiskQueue<T>(_ block: () -> T) -> T {
        if DispatchQueue.getSpecific(key: queueKey) != nil {
            return block()
        } else {
            return diskQueue.sync { block() }
        }
    }

    private func diskFilePath(for url: URL) -> URL {
        let hash = SHA256.hash(data: Data(url.absoluteString.utf8))
            .compactMap { String(format: "%02x", $0) }
            .joined()
        return diskCacheURL.appendingPathComponent(hash)
    }

    func image(for url: URL) -> UIImage? {
        if let memoryImage = memoryCache.object(forKey: url as NSURL) {
            return memoryImage
        }

        let filePath = diskFilePath(for: url)
        guard fileManager.fileExists(atPath: filePath.path) else { return nil }

        let diskImage: UIImage? = performOnDiskQueue {
            guard let data = try? Data(contentsOf: filePath) else {
                return nil
            }
            if let decoded = ImageDecoder.decodeSafely(from: data) {
                return decoded
            } else {
                try? fileManager.removeItem(at: filePath)
                return nil
            }
        }

        if let image = diskImage {
            memoryCache.setObject(image, forKey: url as NSURL)
            return image
        }

        return nil
    }

    func insert(data: Data? = nil, image: UIImage, for url: URL) {
        memoryCache.setObject(image, forKey: url as NSURL)

        let filePath = diskFilePath(for: url)
        diskQueue.async { [weak self] in
            guard let _ = self else { return }
            let diskData = data ?? image.jpegData(compressionQuality: 0.85)
            guard let diskData = diskData, diskData.count > 200 else { return }
            try? diskData.write(to: filePath, options: .atomic)
        }
    }

    func insert(_ image: UIImage, for url: URL) {
        insert(data: nil, image: image, for: url)
    }

    func clearCache() {
        memoryCache.removeAllObjects()
        diskQueue.async { [weak self] in
            guard let self = self else { return }
            try? self.fileManager.removeItem(at: self.diskCacheURL)
            try? self.fileManager.createDirectory(at: self.diskCacheURL, withIntermediateDirectories: true)
        }
        print("🧹 [ImageCache] Memory and Disk cache cleared")
    }

    func prefetch(urlString: String?) {
        guard let rawUrlString = urlString else { return }
        let cleanUrlString = ImageURLHelper.sanitize(urlString: rawUrlString)
        guard let url = URL(string: cleanUrlString) else { return }
        if memoryCache.object(forKey: url as NSURL) != nil { return }
        let filePath = diskFilePath(for: url)
        if fileManager.fileExists(atPath: filePath.path) { return }

        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")

        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, _ in
            guard let self = self else { return }
            if let data = data,
               let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode),
               let image = ImageDecoder.decodeSafely(from: data) {
                self.insert(data: data, image: image, for: url)
            } else if let proxyURL = ImageProxyHelper.proxyURL(for: cleanUrlString) {
                var proxyReq = URLRequest(url: proxyURL)
                proxyReq.timeoutInterval = 10
                let proxyTask = URLSession.shared.dataTask(with: proxyReq) { [weak self] pData, pResp, _ in
                    guard let self = self else { return }
                    if let pData = pData,
                       let pHttp = pResp as? HTTPURLResponse, (200...299).contains(pHttp.statusCode),
                       let pImage = ImageDecoder.decodeSafely(from: pData) {
                        self.insert(data: pData, image: pImage, for: url)
                    }
                }
                proxyTask.resume()
            }
        }
        task.resume()
    }
}

struct PublisherEditorialFallbackView: View {
    let publisherName: String?

    var monogram: String {
        let name = publisherName ?? "News"
        if name.count <= 4 {
            return name.uppercased()
        }
        let words = name.split(separator: " ")
        if words.count >= 2 {
            return "\(words[0].prefix(1))\(words[1].prefix(1))".uppercased()
        }
        return String(name.prefix(3)).uppercased()
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.14, blue: 0.22),
                    Color(red: 0.05, green: 0.07, blue: 0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(Color.appBlue.opacity(0.25))
                        .frame(width: 36, height: 36)

                    Image(systemName: "newspaper.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.appBlue)
                }

                Text(monogram)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(1)
            }
            .padding(8)
        }
    }
}

struct ArticleImageView: View {
    let urlString: String?
    var fallbackName: String? = nil
    var publisherName: String? = nil
    var contentMode: ContentMode = .fill

    @State private var loadedImage: UIImage?
    @State private var isLoading = false
    @State private var hasFailed = false

    var body: some View {
        ZStack {
            if let loadedImage = loadedImage {
                Image(uiImage: loadedImage)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .transition(.opacity)
            } else if hasFailed {
                PublisherEditorialFallbackView(publisherName: publisherName)
            } else {
                ZStack {
                    Color(uiColor: .systemGray6)
                    Image(systemName: "photo")
                        .font(.system(size: 22))
                        .foregroundColor(Color(uiColor: .systemGray3))
                }
                .shimmer()
            }
        }
        .animation(.easeInOut(duration: 0.2), value: loadedImage != nil)
        .onAppear {
            loadImage()
        }
        .onChange(of: urlString) { _ in
            loadedImage = nil
            hasFailed = false
            loadImage()
        }
    }

    private func loadImage() {
        guard let rawUrlString = urlString else {
            hasFailed = true
            return
        }
        let cleanUrlString = ImageURLHelper.sanitize(urlString: rawUrlString)
        guard let url = URL(string: cleanUrlString) else {
            hasFailed = true
            return
        }

        if let cached = ImageCache.shared.image(for: url) {
            self.loadedImage = cached
            self.isLoading = false
            return
        }

        isLoading = true
        hasFailed = false

        Task {
            var request = URLRequest(url: url)
            request.timeoutInterval = 10
            request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")

            var downloadedData: Data? = nil
            var downloadedImage: UIImage? = nil

            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode),
                   let image = ImageDecoder.decodeSafely(from: data) {
                    downloadedData = data
                    downloadedImage = image
                } else if let httpResponse = response as? HTTPURLResponse, [401, 403, 404, 500, 502, 503].contains(httpResponse.statusCode) {
                    // Try proxy fallback for hotlink-protected publishers like nasaspaceflight.com
                    if let proxyURL = ImageProxyHelper.proxyURL(for: cleanUrlString) {
                        var proxyReq = URLRequest(url: proxyURL)
                        proxyReq.timeoutInterval = 10
                        if let (proxyData, proxyResp) = try? await URLSession.shared.data(for: proxyReq),
                           let proxyHttp = proxyResp as? HTTPURLResponse, (200...299).contains(proxyHttp.statusCode),
                           let proxyImage = ImageDecoder.decodeSafely(from: proxyData) {
                            downloadedData = proxyData
                            downloadedImage = proxyImage
                        }
                    }
                }
            } catch {
                if let proxyURL = ImageProxyHelper.proxyURL(for: cleanUrlString) {
                    var proxyReq = URLRequest(url: proxyURL)
                    proxyReq.timeoutInterval = 10
                    if let (proxyData, proxyResp) = try? await URLSession.shared.data(for: proxyReq),
                       let proxyHttp = proxyResp as? HTTPURLResponse, (200...299).contains(proxyHttp.statusCode),
                       let proxyImage = ImageDecoder.decodeSafely(from: proxyData) {
                        downloadedData = proxyData
                        downloadedImage = proxyImage
                    }
                }
            }

            if let data = downloadedData, let image = downloadedImage {
                ImageCache.shared.insert(data: data, image: image, for: url)
                await MainActor.run {
                    self.loadedImage = image
                    self.isLoading = false
                }
            } else {
                await MainActor.run {
                    self.hasFailed = true
                    self.isLoading = false
                }
            }
        }
    }
}
