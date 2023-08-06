#!/usr/bin/swift

import Foundation

guard CommandLine.argc == 2 else {
	print("Usage: \(CommandLine.arguments[0]) <FCPXML file>")
	exit(1)
}

/* read XML document */
let url = URL(fileURLWithPath: CommandLine.arguments[1])
let xml = try XMLDocument(contentsOf: url)

/* remove notes */
try xml.nodes(forXPath: "//note").forEach {
	let parent = $0.parent as! XMLElement
	parent.removeChild(at: $0.index)
}

/* remove clip ranking */
try xml.nodes(forXPath: "//metadata/md[@key='com.apple.proapps.studio.metadataLocation']").forEach {
	let parent = $0.parent as! XMLElement
	parent.removeChild(at: $0.index)
}

/* remove top-level clips */
try xml.nodes(forXPath: "/fcpxml/library/event/clip").forEach {
	let parent = $0.parent as! XMLElement
	parent.removeChild(at: $0.index)
}

/* fix wrongly encoded umlauts */
try xml.nodes(forXPath: "//asset/@src").forEach {
	$0.stringValue = $0.stringValue!
		.replacingOccurrences(of: "a%CC%88", with: "%C3%A4")
		.replacingOccurrences(of: "o%CC%88", with: "%C3%B6")
		.replacingOccurrences(of: "u%CC%88", with: "%C3%BC")
}

/* remove broken audio adjustments */
try xml.nodes(forXPath: "//adjust-volume").forEach {
	let amount = ($0 as! XMLElement).attribute(forName: "amount")!.stringValue!
	guard amount == "-96dB" else { return }
	let parent = $0.parent as! XMLElement
	parent.removeChild(at: $0.index)
}
try xml.nodes(forXPath: "//adjust-panner").forEach {
	let amount = ($0 as! XMLElement).attribute(forName: "amount")!.stringValue!
	guard amount == "-100.0" else { return }
	let parent = $0.parent as! XMLElement
	parent.removeChild(at: $0.index)
}

/* adjust VFX titles */
try xml.nodes(forXPath: "//title/@name").forEach {
	$0.stringValue = $0.stringValue!
		.replacingOccurrences(of: "VFX - Text im unteren Drittel", with: "VFX")
}
try xml.nodes(forXPath: "//title/text-style-def/text-style/@fontSize").forEach {
	$0.stringValue = $0.stringValue!
		.replacingOccurrences(of: "108", with: "75")
}

/* remove drop shadow effect */
try xml.nodes(forXPath: "//filter-video[@name='Drop Shadow']").forEach {
	let parent = $0.parent as! XMLElement
	parent.removeChild(at: $0.index)
}

/* fix corner distortion to mirror image */
try xml.nodes(forXPath: "//adjust-corners").forEach {
	let topLeft = ($0 as! XMLElement).attribute(forName: "topLeft")!
	let topRight = ($0 as! XMLElement).attribute(forName: "topRight")!
	let botRight = ($0 as! XMLElement).attribute(forName: "botRight")!
	let botLeft = ($0 as! XMLElement).attribute(forName: "botLeft")!
	topLeft.stringValue = topLeft.stringValue!.replacingOccurrences(of: "133.333333333333", with: "177.7777777778")
	topRight.stringValue = topRight.stringValue!.replacingOccurrences(of: "133.333333333333", with: "177.7777777778")
	botRight.stringValue = botRight.stringValue!.replacingOccurrences(of: "133.333333333333", with: "177.7777777778")
	botLeft.stringValue = botLeft.stringValue!.replacingOccurrences(of: "133.333333333333", with: "177.7777777778")
}

/* remove unneeded warning markers */
try xml.nodes(forXPath: "//marker").forEach {
	let knownGood = [
		"Anchor Point ignored",
		"Bewegungsweichzeichner filter ignored (enabled)",
		"Dip to Color Dissolve → Fade to Color",
		"Drop Shadow → Drop Shadow effect (disabled)",
		"Einfarbig → Custom generator",
		"Fade In Fade Out Dissolve → Fade to Color",
		"Motion Blur ignored",
		"Solarisation filter ignored (enabled)",
		"Text im unteren Drittel → Middle"
	]
	let text = ($0 as! XMLElement).attribute(forName: "value")!.stringValue!
	if knownGood.contains(text) {
		let parent = $0.parent as! XMLElement
		parent.removeChild(at: $0.index)
	}
}


/* helper function for time adjustments */
let timeBase = 8708700

func time(_ s: String) -> Int {
	if s.hasSuffix("/8708700s") {
		return Int(s.dropLast(9))!
	} else if s.hasSuffix("/791700s") {
		return Int(s.dropLast(8))! * 11
	} else if s.hasSuffix("/825s") {
		return Int(s.dropLast(5))! * 10556
	} else if s.hasSuffix("/725s") {
		return Int(s.dropLast(5))! * 12012
	} else if s.hasSuffix("/325s") {
		return Int(s.dropLast(5))! * 26796
	} else if s.hasSuffix("/175s") {
		return Int(s.dropLast(5))! * 49764
	} else if s.hasSuffix("/91s") {
		return Int(s.dropLast(4))! * 95700
	} else if s.hasSuffix("/75s") {
		return Int(s.dropLast(4))! * 116116
	} else if s.hasSuffix("/65s") {
		return Int(s.dropLast(4))! * 133980
	} else if s.hasSuffix("/50s") {
		return Int(s.dropLast(4))! * 174174
	} else if s.hasSuffix("/35s") {
		return Int(s.dropLast(4))! * 248820
	} else if s.hasSuffix("/29s") {
		return Int(s.dropLast(4))! * 300300
	} else if s.hasSuffix("/25s") {
		return Int(s.dropLast(4))! * 348348
	} else if s.hasSuffix("/20s") {
		return Int(s.dropLast(4))! * 435435
	} else if s.hasSuffix("/15s") {
		return Int(s.dropLast(4))! * 580580
	} else if s.hasSuffix("/11s") {
		return Int(s.dropLast(4))! * 791700
	} else if s.hasSuffix("/5s") {
		return Int(s.dropLast(3))! * 1741740
	} else if s.hasSuffix("s") && !s.contains("/") {
		return Int(s.dropLast(1))! * 8708700
	} else {
		fatalError("unexpected start time: \(s)")
	}
}

func time(_ node: XMLNode?) -> Int {
	return time(node!.stringValue!)
}

/* fix audioStart for compound clips */
try xml.nodes(forXPath: "//clip/spine/clip/clip").forEach {
	let inner = $0 as! XMLElement
	let outer = $0.parent as! XMLElement
	let top = outer.parent!.parent as! XMLElement

	let innerStart = time(inner.attribute(forName: "start"))
	let outerStart = time(outer.attribute(forName: "start"))
	let topStart = time(top.attribute(forName: "audioStart"))

	let fixedStart = topStart - (innerStart - outerStart)
	top.attribute(forName: "audioStart")!.stringValue = "\(fixedStart)/\(timeBase)s"
}

/* fix time-remapped compound clips */
try xml.nodes(forXPath: "//clip[timeMap]/spine/clip/clip/audio").forEach {
	let innerAudio = $0 as! XMLElement
	let inner = innerAudio.parent as! XMLElement
	let outer = inner.parent as! XMLElement
	let outerVideo = outer.child(at: 0) as! XMLElement
	let top = outer.parent!.parent as! XMLElement

	let timeMapReverse = Dictionary(uniqueKeysWithValues: try! top.nodes(forXPath: "timeMap/timept").map {
		let time = ($0 as! XMLElement).attribute(forName: "time")!.stringValue!
		let value = ($0 as! XMLElement).attribute(forName: "value")!.stringValue!
		return (time, value)
	})

	let innerStart = inner.attribute(forName: "start")!.stringValue!
	innerAudio.attribute(forName: "offset")!.stringValue = innerStart
	innerAudio.attribute(forName: "start")!.stringValue = innerStart

	let outerOffset = outer.attribute(forName: "offset")!.stringValue!
	let outerStart = outer.attribute(forName: "start")!.stringValue!
	outer.attribute(forName: "offset")!.stringValue = timeMapReverse[outerOffset]!
	outer.attribute(forName: "start")!.stringValue = timeMapReverse[outerStart]!
	outerVideo.attribute(forName: "offset")!.stringValue = timeMapReverse[outerStart]!
	outerVideo.attribute(forName: "start")!.stringValue = timeMapReverse[outerStart]!

	// from identical audio duration we assume identical audio start
//	assert(top.attribute(forName: "duration")!.stringValue! == top.attribute(forName: "audioDuration")!.stringValue!)
	let topStart = top.attribute(forName: "start")!.stringValue!
	top.attribute(forName: "audioStart")!.stringValue = topStart
}

print(xml)
