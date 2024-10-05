package gdoc;
import sys.io.File;
import gdoc.NodeGraph;
import gdoc.PowerDiagram;

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
    public function new(width : Float = 1000.0, height : Float = 1000.0, margin : Float = 100.0) {
        this.width = width;
        this.height = height;
        this.margin = margin;

    }
    public var width : Float;
    public var height : Float;
    public var margin : Float;
}

class SVGGenerate {

    private static function startSVG( ) : StringBuf {
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
        return svgContent;
    }

    public static function finishSVG( path : String, svgContent : StringBuf ) {
        svgContent.add('</svg>\n');
        File.saveContent(path, svgContent.toString());
    }

    public static function writePointField(path : String,field:PointField2D, frame: Frame = null, stylizer : (Point2D, SVGNodeAttributes) -> Void = null) {
        var svgContent = startSVG(); 
        var bounds = Rect2D.infiniteEmpty();

        bounds.expandToIncludePoints(field);
        frame = getFrameOrDefault(frame);

        var range_x = bounds.width;
        var range_y = bounds.height;
        var x_scale = (frame.width - 2 * frame.margin) / (range_x);
        var y_scale = (frame.height - 2 * frame.margin) / (range_y);
        var uni_scale = x_scale < y_scale ? x_scale : y_scale;

        var attr = new SVGNodeAttributes();

        attr.r = Math.min(range_x, range_y) / 50.0;
        attr.fill = "lightblue";
        attr.stroke = "black";
        attr.recursive = true;
        attr.r = attr.r * uni_scale;

        for (point in field) {
            var x = (point.x - bounds.xmin) * uni_scale + frame.margin;
            var y = frame.height - ((point.y - bounds.ymin) * uni_scale + frame.margin);
            attr.x = x;
            attr.y = y;
            if (stylizer != null) {
                stylizer(point, attr);
            }
            svgContent.add('<circle cx="${x}" cy="${y}" r="${attr.r}" fill="${attr.fill}" stroke="${attr.stroke}"/>\n');
        }

        finishSVG(path, svgContent);
    }

    static function getFrameOrDefault(frame: Frame) {
        if (frame == null) {
            frame = new Frame();
        }
        return frame;
    }

    public static function writePowerDiagram(path : String,diagram: Map<Int, PowerCell>, centers : Array<WeightedPoint2D>, frame: Frame = null) {
        var svgContent = startSVG(); 
        
        var attr = new SVGNodeAttributes();

        var bounds = Rect2D.infiniteEmpty();

        for (cell in diagram) {
            bounds.expandToIncludePoints(cell);
        }

        frame = getFrameOrDefault(frame);

        var range_x = bounds.width;
        var range_y = bounds.height;
        var x_scale = (frame.width - 2 * frame.margin) / (range_x);
        var y_scale = (frame.height - 2 * frame.margin) / (range_y);
        var uni_scale = x_scale < y_scale ? x_scale : y_scale;

        attr.r = Math.min(range_x, range_y) / 20.0;
        attr.fill = "lightblue";
        attr.stroke = "black";
        attr.recursive = true;
        attr.r = attr.r * uni_scale;

        function transformPoint( p : Point2D) : Point2D {
            var x = (p.x - bounds.xmin) * uni_scale + frame.margin;
            var y = frame.height - ((p.y - bounds.ymin) * uni_scale + frame.margin);
            return new Point2D(x, y);
        }
        for (cell in diagram.keyValueIterator()) {
            for (i in 0...cell.value.length) {
                var p0 = transformPoint(cell.value[i]);
                var p1 = transformPoint(cell.value[(i + 1) % cell.value.length]);
                svgContent.add('<line x1="${p0.x}" y1="${p0.y}" x2="${p1.x}" y2="${p1.y}" stroke="black" />\n');
            }

            var originalCenter = centers[cell.key];

            final PRECISION = 1e-3;
            var center = transformPoint(new Point2D(originalCenter.x, originalCenter.y));
            svgContent.add('<circle cx="${center.x}" cy="${center.y}" r="${attr.r}" fill="${attr.fill}" stroke="${attr.stroke}"/>\n');
            svgContent.add('<text x="${center.x}" y="${center.y + 5}" text-anchor="middle" font-size="12px" font-family="Arial">${cell.key}[${Math.round(originalCenter.z / PRECISION)* PRECISION}]</text>\n');
        }
        
        finishSVG(path, svgContent);
    }

    public static function writeNodeGraph( path : String, graph : NodeGraph, attrFn : ( Node, SVGNodeAttributes) -> Void = null, frame: Frame = null ) {
        var svgContent = startSVG();        

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
        var margin = frame != null ? frame.margin : 100.0;
        var width = frame != null ? frame.width : 1000.0;
        var height = frame != null ? frame.height : 1000.0;

        var x_scale = (width - 2 * margin) / (max_x - min_x);
        var y_scale = (height - 2 * margin) / (max_y - min_y);

        var uni_scale = x_scale < y_scale ? x_scale : y_scale;


        function drawNode2D( node : Node, attr : SVGNodeAttributes) {
            attr.x = (node.x - min_x) * uni_scale + margin;
            attr.y = (node.y - min_y) * uni_scale + margin;
            
            attr.r = 1.0;
            attr.fill = "lightblue";
            attr.stroke = "black";
            attr.text = node.name;
            attr.recursive = true;
            if (attrFn != null) {
                attrFn(node, attr);
            }
            attr.r = attr.r * uni_scale;

            svgContent.add('<circle cx="${attr.x}" cy="${height - attr.y}" r="${attr.r}" fill="${attr.fill}" stroke="${attr.stroke}"/>\n');

            for (connection in node.getNonChildrenOutgoingEdges()) {
                var target = cast(connection.target, Node);
                var target_x = (target.x - min_x) * uni_scale + margin;
                var target_y = (target.y - min_y) * uni_scale + margin;

                var delta_x = target_x - attr.x;
                var delta_y = target_y - attr.y;
                var length = Math.sqrt(delta_x * delta_x + delta_y * delta_y);
                delta_x /= length;
                delta_y /= length;

                var x0 = attr.x + delta_x * attr.r* 1.5;
                var y0 = attr.y + delta_y * attr.r* 1.5;
                var x1 = target_x - delta_x * attr.r * 1.5;
                var y1 = target_y - delta_y * attr.r* 1.5;
                svgContent.add('<line x1="${x0}" y1="${height - y0}" x2="${x1}" y2="${height - y1}" stroke="black" marker-end="url(#arrow)" />\n');
            }
            
            if (attr.text != null) {
                svgContent.add('<text x="${attr.x}" y="${height - (attr.y + 5)}" text-anchor="middle" font-size="12px" font-family="Arial">${attr.text}</text>\n');
            }

            if (attr.recursive && node.hasChildren()) {
            }
        }
        
        for (node in nodes) {
            if (node.getParent() == null) {
                drawNode2D(node, attr);
            }
        }


        // Save the SVG content to a file
        finishSVG(path, svgContent);
    }

}