#!/usr/bin/swift

import Foundation

guard CommandLine.argc == 2 else {
	print("Usage: \(CommandLine.arguments[0]) <FCPXML file>")
	exit(1)
}

/* read XML document */
let url = URL(fileURLWithPath: CommandLine.arguments[1])
let xml = try XMLDocument(contentsOf: url, options: 0)

/* delete unstable nodes */
// FIXME: check what’s really going on here
let unstablePaths = "/fcpxml/resources/asset/bookmark" + "|" +
	"/fcpxml/resources/asset/@id" + "|" +
	"/fcpxml/resources/media//@ref" + "|" +
	"/fcpxml/library/event//@ref"
try xml.nodes(forXPath: unstablePaths).forEach { $0.detach() }

/* sort resource and event nodes */
try xml.nodes(forXPath: "/fcpxml/resources|/fcpxml/library/event").forEach { node in
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
