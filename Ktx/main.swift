import MachO
import WebKit

let parser = ArgParser(helptext: "Usage: ktx \"x^2\" output.tiff", version: "Version 0.1.0")
parser.newInt("size s", fallback: 24)
parser.newFlag("inline i")
parser.newFlag("open o")
parser.parse()

if parser.numArgs() == 0 {
	print("Error: no expression provided")
	exit(1)
}

let expression = parser.getArgs()[0].replacingOccurrences(of: "\\", with: "\\\\")
let size = parser.getInt("size")
let display = !parser.getFlag("inline")
let renderCode = "window.renderEquation('\(expression)', \(size), \(display))"

var dest = URL(fileURLWithPath: NSTemporaryDirectory() + "ktx-render.tiff")
var openWhenDone = true
if parser.numArgs() == 2 {
	let wd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
	dest = URL(fileURLWithPath: parser.getArgs()[1], relativeTo: wd)
	openWhenDone = parser.getFlag("open")
}

var webView: WKWebView!

func screenshot(rect: CGRect) {
	let config = WKSnapshotConfiguration()
	config.rect = rect
	webView.takeSnapshot(with: config, completionHandler: {(img, err) in
		guard let rep = img?.tiffRepresentation else {
			exit(1)
		}
		do {
			try rep.write(to: dest)
		} catch {
			print("Error: unable to save image file")
			exit(1)
		}
		if openWhenDone {
			NSWorkspace.shared.openFile(dest.path, withApplication: "Preview")
		}
		exit(0)
	})
}

class WebViewDelegate: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
	func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
		webView.evaluateJavaScript(renderCode, completionHandler: nil)
	}
	func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
		if message.name == "error" {
			print("Error: invalid equation code")
			exit(1)
		} else if message.name == "renderDone" {
			guard let res = message.body as? String else {
				exit(1)
			}
			let d = res.split(separator: ",").map { Int($0) }
			guard d.count == 4 else {
				exit(1)
			}
			let padding = display ? 10 : 3
			let rect = CGRect(x: d[0]! - padding,
							  y: d[1]! - padding,
							  width: d[2]! + 2*padding,
							  height: d[3]! + 2*padding)
			screenshot(rect: rect)
		}
	}
}

let del = WebViewDelegate()

let config = WKWebViewConfiguration()
let controller = WKUserContentController()
controller.add(del, name: "renderDone")
controller.add(del, name: "error")
config.userContentController = controller

webView = WKWebView.init(frame: CGRect(x: 0, y: 0, width: 1000, height: 300), configuration: config)
webView.navigationDelegate = del

// Access the HTML code embedded in the binary
// (adapted from https://stackoverflow.com/a/49438718)
if let handle = dlopen(nil, RTLD_LAZY) {
	defer { dlclose(handle) }

	if let ptr = dlsym(handle, MH_EXECUTE_SYM) {
		let mhExecHeaderPtr = ptr.assumingMemoryBound(to: mach_header_64.self)

		var size: UInt = 0
		guard let section = getsectiondata(mhExecHeaderPtr, "__KATEX", "__base", &size) else {
			exit(1)
		}
		let code = String(cString: section)
		webView.loadHTMLString(code, baseURL: nil)
		RunLoop.main.run()
	}
}
