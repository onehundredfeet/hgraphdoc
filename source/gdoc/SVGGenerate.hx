package gdoc;
import sys.io.File;
import gdoc.NodeGraph2D;

class SVGNodeAttributes {
    public function new() {

    }
    public var x : Float;
    public var y : Float;
    public var r : Float;
    public var fill : String;
    public var stroke : String;
    public var text : String;
    public var recursive : Bool;
}

class SVGGenerate {

    public static function writeNodeGraph2D( path : String, graph : NodeGraph2D, attrFn : ( NodeGraphNode2D, SVGNodeAttributes) -> Void = null ) {
        var svgContent = new StringBuf();
        svgContent.add('<?xml version="1.0" encoding="UTF-8" standalone="no"?>\n');
        svgContent.add('<svg xmlns="http://www.w3.org/2000/svg" version="1.1">\n');

        // Define nodes with positions
        var nodes = graph.nodes;

        // Draw nodes as circles and add labels
        var attr = new SVGNodeAttributes();

        function drawNode2D( node : NodeGraphNode2D, attr : SVGNodeAttributes) {
            for (connection in node.outgoing) {
                var target = cast(connection.target, NodeGraphNode2D);
                svgContent.add('<line x1="${node.x}" y1="${node.y}" x2="${target.x}" y2="${target.y}" stroke="black"/>\n');
            }
            attr.x = node.x;
            attr.y = node.y;
            attr.r = 1.0;
            attr.fill = "lightblue";
            attr.stroke = "black";
            attr.text = node.name;
            attr.recursive = true;
            if (attrFn != null) {
                attrFn(node, attr);
            }
            svgContent.add('<circle cx="${attr.x}" cy="${attr.y}" r="${attr.r}" fill="${attr.fill}" stroke="${attr.stroke}"/>\n');
            if (attr.text != null) {
                svgContent.add('<text x="${attr.x}" y="${attr.y + 5}" text-anchor="middle" font-size="12px" font-family="Arial">${attr.text}</text>\n');
            }

            if (attr.recursive && node.hasChildren()) {
            }
        }
        
        for (node in nodes) {
            if (node.parent == null) {
                drawNode2D(node, attr);
            }
        }

        svgContent.add('</svg>\n');

        // Save the SVG content to a file
        File.saveContent(path, svgContent.toString());
    }

}