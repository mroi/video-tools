#!/usr/bin/swift

import Foundation

guard CommandLine.argc == 2 else {
	print("Usage: \(CommandLine.arguments[0]) <FCPXML file>")
	exit(1)
}

/* read XML document */
let url = URL(fileURLWithPath: CommandLine.arguments[1])
let xml = try XMLDocument(contentsOf: url)

/* path representation of a node’s location */
typealias XMLNodePath = String
func path(to node: XMLNode) -> XMLNodePath {
	var result = ""
	if let parent = node.parent {
		result = path(to: parent) + "/"
	}
	result += node.name ?? ""
	if let e = node as? XMLElement, let name = e.attribute(forName: "name") {
		result += ":" + name.stringValue!
	}
	return result
}

/* FCP container for this node */
func container(of node: XMLNode) -> XMLNodePath {
	let parent = node.parent!
	switch parent.name! {
	case "resources", "project", "event":
		return path(to: parent)
	default:
		return container(of: parent)
	}
}

/* report keywords unless they are part of a visible keyword collection */
var keywordCollections: [XMLNodePath : [String]] = [:]
try xml.nodes(forXPath: "//keyword-collection").forEach {
	let container = container(of: $0)
	let element = $0 as! XMLElement
	let name = element.attribute(forName: "name")!.stringValue!
	keywordCollections[container, default: []].append(name)
}
try xml.nodes(forXPath: "//keyword").forEach {
	let container = container(of: $0)
	let element = $0 as! XMLElement
	let value = element.attribute(forName: "value")!.stringValue!
	let keywords = value.split(separator: ",").map { $0.drop(while: { $0.isWhitespace }) }
	let collection = keywordCollections[container] ?? []
	let known = keywords.allSatisfy { collection.contains(String($0)) }
	if !known {
		print("keywords \(keywords) in \(path(to: $0))")
	}
}

/* report discouraged methods of disabling clip audio */
try xml.nodes(forXPath: "//adjust-volume|//audio-role-source/mute").forEach {
	// FIXME: this also matches some audio volume automations
	print("clip audio muted by discouraged method in \(path(to: $0)): \($0)")
}
