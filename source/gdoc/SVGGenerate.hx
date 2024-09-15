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

class Frame {
    public function new() {

    }
    public var width : Float;
    public var height : Float;
    public var margin : Float;
}

class SVGGenerate {

    public static function writeNodeGraph2D( path : String, graph : NodeGraph2D, attrFn : ( NodeGraphNode2D, SVGNodeAttributes) -> Void = null, frame: Frame = null ) {
        var svgContent = new StringBuf();
        svgContent.add('<?xml version="1.0" encoding="UTF-8" standalone="no"?>\n');
        svgContent.add('<svg xmlns="http://www.w3.org/2000/svg" version="1.1">\n');

        // Define nodes with positions
        var nodes = graph.nodes;

        // Draw nodes as circles and add labels
        var attr = new SVGNodeAttributes();
        var min_x = 100000.0;
        var min_y = 100000.0;
        var max_x = -100000.0;
        var max_y = -100000.0;

        for (node in nodes) {
            if (node.x < min_x) min_x = node.x;
            if (node.y < min_y) min_y = node.y;
            if (node.x > max_x) max_x = node.x;
            if (node.y > max_y) max_y = node.y;
        }
        var range_x = max_x - min_x;
        var range_y = max_y - min_y;
        var margin = frame != null ? frame.margin : 100.0;
        var width = frame != null ? frame.width : 1000.0;
        var height = frame != null ? frame.height : 1000.0;


        function drawNode2D( node : NodeGraphNode2D, attr : SVGNodeAttributes) {
            attr.x = (node.x - min_x) / range_x * (width - 2 * margin) + margin;
            attr.y = (node.y - min_y) / range_y * (height - 2 * margin) + margin;
            
            for (connection in node.outgoing) {
                var target = cast(connection.target, NodeGraphNode2D);
                var target_x = (target.x - min_x) / range_x * (width - 2 * margin) + margin;
                var target_y = (target.y - min_y) / range_y * (height - 2 * margin) + margin;

                svgContent.add('<line x1="${attr.x}" y1="${attr.y}" x2="${target_x}" y2="${target_y}" stroke="black"/>\n');
            }

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