package gdoc;
import sys.io.File;
import gdoc.NodeGraph;
import gdoc.PowerDiagram;
import gdoc.SVGWriter;

class SVGPrimAttributes extends SVGAttributes {
    public var x0 : Float;
    public var y0 : Float;
    public var x1 : Float;
    public var y1 : Float;
    public var r : Float;
    public var recursive : Bool;
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

    public static function writeTriangles( path: String, triangles : Array<Triangle2D>, frame: ImageFrame = null) {
        var bounds = Rect2D.infiniteEmpty();
        bounds.expandToIncludeTriangles(triangles);

        var writer = new SVGWriter();
        writer.bound(bounds, true, frame);

        var attr = new SVGPrimAttributes();
        attr.fill = "lightblue";
        attr.stroke = "black";
        attr.recursive = true;
        attr.r = 1.0;

        for (triangle in triangles) {
            writer.polygon([triangle.a, triangle.b, triangle.c], attr);
        }

        writer.finishAndWrite(path);
    }

    public static function writePointField(path : String,field:PointField2D, frame: ImageFrame = null, stylizer : (Point2D, SVGPrimAttributes) -> Void = null) {
       var writer = new SVGWriter();
        var bounds = Rect2D.infiniteEmpty();

        bounds.expandToIncludePoints(field);
        writer.bound(bounds, true, frame);

        var uni_scale = frame.scale;

        var attr = new SVGPrimAttributes();

        attr.r = Math.min(bounds.width, bounds.height) / 50.0;
        attr.fill = "lightblue";
        attr.stroke = "black";
        attr.recursive = true;
        attr.r = attr.r * uni_scale;

        for (point in field) {
            // var x = (point.x - bounds.xmin) * uni_scale + frame.margin;
            // var y = frame.height - ((point.y - bounds.ymin) * uni_scale + frame.margin);
            attr.x0 = point.x;
            attr.y0 = point.y;
            if (stylizer != null) {
                stylizer(point, attr);
            }
            writer.circle(attr.x0, attr.y0, attr.r, attr);
        }

        writer.finishAndWrite(path);
    }

    public static function writePowerDiagram(path : String,diagram: Map<Int, PowerCell>, centers : Array<WeightedPoint2D>, frame: ImageFrame = null) {
        var writer = new SVGWriter();
        
        var attr = new SVGPrimAttributes();

        var bounds = Rect2D.infiniteEmpty();

        for (cell in diagram) {
            bounds.expandToIncludePoints(cell);
        }

        writer.bound(bounds,true);

        attr.r = Math.min(bounds.width, bounds.height) / 20.0;
        attr.fill = "lightblue";
        attr.stroke = "black";
        attr.recursive = true;

        for (cell in diagram.keyValueIterator()) {
            for (i in 0...cell.value.length) {
                var p0 = cell.value[i];
                var p1 = cell.value[(i + 1) % cell.value.length];
                writer.line(p0.x, p0.y, p1.x, p1.y, attr);
//                svgContent.add('<line x1="${p0.x}" y1="${p0.y}" x2="${p1.x}" y2="${p1.y}" stroke="black" />\n');
            }

            var originalCenter = centers[cell.key];

            final PRECISION = 1e-3;
            writer.circle(originalCenter.x, originalCenter.y, attr.r, attr);
//            svgContent.add('<circle cx="${center.x}" cy="${center.y}" r="${attr.r}" fill="${attr.fill}" stroke="${attr.stroke}"/>\n');
//            svgContent.add('<text x="${center.x}" y="${center.y + 5}" text-anchor="middle" font-size="12px" font-family="Arial">${cell.key}[${Math.round(originalCenter.z / PRECISION)* PRECISION}]</text>\n');
            writer.text('${cell.key}[${Math.round(originalCenter.z / PRECISION)* PRECISION}]', originalCenter.x, originalCenter.y + 5, attr);
        }
        
        writer.finishAndWrite(path);
    }

    public static function writeNodeGraph( path : String, graph : NodeGraph, attrFn : ( Node, SVGPrimAttributes) -> Void = null, frame: ImageFrame = null ) {
        var svgContent = startSVG();        

        // Define nodes with positions
        var nodes = graph.nodes;

        // Draw nodes as circles and add labels
        var attr = new SVGPrimAttributes();
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


        function drawNode2D( node : Node, attr : SVGPrimAttributes) {
            attr.x0 = (node.x - min_x) * uni_scale + margin;
            attr.y0 = (node.y - min_y) * uni_scale + margin;
            
            attr.r = 1.0;
            attr.fill = "lightblue";
            attr.stroke = "black";
            attr.text = node.name;
            attr.recursive = true;
            if (attrFn != null) {
                attrFn(node, attr);
            }
            attr.r = attr.r * uni_scale;

            svgContent.add('<circle cx="${attr.x0}" cy="${height - attr.y0}" r="${attr.r}" fill="${attr.fill}" stroke="${attr.stroke}"/>\n');

            for (connection in node.getNonChildrenOutgoingEdges()) {
                var target = cast(connection.target, Node);
                var target_x = (target.x - min_x) * uni_scale + margin;
                var target_y = (target.y - min_y) * uni_scale + margin;

                var delta_x = target_x - attr.x0;
                var delta_y = target_y - attr.y0;
                var length = Math.sqrt(delta_x * delta_x + delta_y * delta_y);
                delta_x /= length;
                delta_y /= length;

                var x0 = attr.x0 + delta_x * attr.r* 1.5;
                var y0 = attr.y0 + delta_y * attr.r* 1.5;
                var x1 = target_x - delta_x * attr.r * 1.5;
                var y1 = target_y - delta_y * attr.r* 1.5;
                svgContent.add('<line x1="${x0}" y1="${height - y0}" x2="${x1}" y2="${height - y1}" stroke="black" marker-end="url(#arrow)" />\n');
            }
            
            if (attr.text != null) {
                svgContent.add('<text x="${attr.x0}" y="${height - (attr.y0 + 5)}" text-anchor="middle" font-size="12px" font-family="Arial">${attr.text}</text>\n');
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