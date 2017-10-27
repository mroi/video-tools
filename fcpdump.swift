#!/usr/bin/swift

import Foundation

guard CommandLine.argc == 2 else {
	print("Usage: \(CommandLine.arguments[0]) <FCPXML file>")
	exit(1)
}

/* read XML document */
let url = URL(fileURLWithPath: CommandLine.arguments[1])
let xml = try XMLDocument(contentsOf: url)

/* delete nodes that change non-deterministically between exports */
// FIXME: check what’s really going on here
let changingPaths = "//@format|//@id|//@ref" + "|" +
	"/fcpxml/resources/asset/bookmark"
try xml.nodes(forXPath: changingPaths).forEach { $0.detach() }

/* sort nodes whose child nodes flip non-deterministically */
let flippingPaths = "//clip|//sync-clip" + "|" +
	"/fcpxml/resources|/fcpxml/library/event"
try xml.nodes(forXPath: flippingPaths).forEach { node in
	var elements: [XMLElement] = []
	node.children?.forEach {
		if $0.kind == .element {
			elements.append($0 as! XMLElement)
		}
	}
	elements.sort { $0.xmlString < $1.xmlString }
	(node as! XMLElement).setChildren(elements)
}

/* dump document in normalized form */
func dump(node: XMLNode, prefix: String) {
	switch node.kind {
		
	case .document:
		node.children?.forEach { dump(node: $0, prefix: prefix) }
		
	case .element:
		let element = node as! XMLElement
		var newPrefix = prefix + "/" + node.name!
		if let name = element.attribute(forName: "name") {
			newPrefix += ":" + name.stringValue!
		}
		print("\(newPrefix)")
		element.attributes?.forEach {
			if $0.name! != "name" {
				dump(node: $0, prefix: newPrefix)
			}
		}
		element.children?.forEach { dump(node: $0, prefix: newPrefix) }

	case .attribute:
		print("\(prefix)/\(node.name!)=\(node.stringValue!)")
		
	default:
		print("\(prefix)/\"\(node.xmlString)\"")
	}
}

dump(node: xml, prefix: "")
