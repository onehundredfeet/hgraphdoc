package gdoc;
import sys.io.File;
import gdoc.NodeGraph;

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

    public static function writeNodeGraph( path : String, graph : NodeGraph, attrFn : ( Node, SVGNodeAttributes) -> Void = null, frame: Frame = null ) {
        var svgContent = new StringBuf();
        svgContent.add('<?xml version="1.0" encoding="UTF-8" standalone="no"?>\n');
        svgContent.add('<svg xmlns="http://www.w3.org/2000/svg" version="1.1">\n');
        svgContent.add('<defs>\n');
        svgContent.add('\t<marker\n');
        svgContent.add('\t\tid="arrow"\n');
        svgContent.add('\t\tviewBox="0 0 10 10"\n');
        svgContent.add('\t\trefX="5"\n');
        svgContent.add('\t\trefY="5"\n');
        svgContent.add('\t\tmarkerWidth="6"\n');
        svgContent.add('\t\tmarkerHeight="6"\n');
        svgContent.add('\t\torient="auto-start-reverse">\n');
        svgContent.add('\t<path d="M 0 0 L 10 5 L 0 10 z" />\n');
        svgContent.add('\t</marker>\n');
        svgContent.add('</defs>\n');

        

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
        var scale = Math.max(range_x, range_y);
        var margin = frame != null ? frame.margin : 100.0;
        var width = frame != null ? frame.width : 1000.0;
        var height = frame != null ? frame.height : 1000.0;


        function drawNode2D( node : Node, attr : SVGNodeAttributes) {
            attr.x = (node.x - min_x) / scale * (width - 2 * margin) + margin;
            attr.y = (node.y - min_y) / scale * (height - 2 * margin) + margin;
            
            attr.r = 1.0;
            attr.fill = "lightblue";
            attr.stroke = "black";
            attr.text = node.name;
            attr.recursive = true;
            if (attrFn != null) {
                attrFn(node, attr);
            }

            svgContent.add('<circle cx="${attr.x}" cy="${attr.y}" r="${attr.r}" fill="${attr.fill}" stroke="${attr.stroke}"/>\n');

            for (connection in node.getNonChildrenOutgoingEdges()) {
                var target = cast(connection.target, Node);
                var target_x = (target.x - min_x) / scale * (width - 2 * margin) + margin;
                var target_y = (target.y - min_y) / scale * (height - 2 * margin) + margin;

                var delta_x = target_x - attr.x;
                var delta_y = target_y - attr.y;
                var length = Math.sqrt(delta_x * delta_x + delta_y * delta_y);
                delta_x /= length;
                delta_y /= length;

                var x0 = attr.x + delta_x * attr.r* 1.5;
                var y0 = attr.y + delta_y * attr.r* 1.5;
                var x1 = target_x - delta_x * attr.r * 1.5;
                var y1 = target_y - delta_y * attr.r* 1.5;
                svgContent.add('<line x1="${x0}" y1="${y0}" x2="${x1}" y2="${y1}" stroke="black" marker-end="url(#arrow)" />\n');
            }
            
            if (attr.text != null) {
                svgContent.add('<text x="${attr.x}" y="${attr.y + 5}" text-anchor="middle" font-size="12px" font-family="Arial">${attr.text}</text>\n');
            }

            if (attr.recursive && node.hasChildren()) {
            }
        }
        
        for (node in nodes) {
            if (node.getParent() == null) {
                drawNode2D(node, attr);
            }
        }

        svgContent.add('</svg>\n');

        // Save the SVG content to a file
        File.saveContent(path, svgContent.toString());
    }

}