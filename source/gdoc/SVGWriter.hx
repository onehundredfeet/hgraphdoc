package gdoc;
import sys.io.File;

class SVGAttributes {
    public function new() {

    }
    public var fill : String;
    public var stroke : String;
    public var text : String;
    public var font : String;
    public var fontSize : Int = 12;
    public var halignment : String;
}

class ImageFrame {
    public function new(width : Float = 1000.0, height : Float = 1000.0, margin : Float = 100.0) {
        this.width = width;
        this.height = height;
        this.margin = margin;

    }

    public function transformX( x : Float ) : Float {
        return (x - bounds.xmin) * scale + margin;
    }
    public function transformY( y : Float ) : Float {
        if (flipY) {
            return height - ((y - bounds.ymin) * scale + margin);
        }
        return (y - bounds.ymin) * scale + margin;        
    }

    public static function generateFrameOrDefault( frame : ImageFrame, bounds: Rect2D, width : Float = 1000.0, height : Float = 1000.0, margin : Float = 100.0 ) {
        if (frame != null) {
            frame = new ImageFrame( frame.width, frame.height, frame.margin);
        } else {
            frame = new ImageFrame( width, height, margin);
        }

        var range_x = bounds.width;
        var range_y = bounds.height;
        var x_scale = (width - 2 * margin) / (range_x);
        var y_scale = (height - 2 * margin) / (range_y);
        frame.scale = x_scale < y_scale ? x_scale : y_scale;
        frame.bounds = bounds;

        return frame;
    }
    public var width : Float;
    public var height : Float;
    public var margin : Float;

    public var scale(default,null) : Float = 1.0;
    public var bounds(default,null) : Rect2D;
    var flipY : Bool = false;
}


class SVGWriter {
    var _buffer = new StringBuf();
    public var defaultFill = "lightblue";
    public var defaultStroke = "black";
    public var defaultFont = "Arial";
    public var defaultHAlignment = "middle";

    var frame : ImageFrame;
    var bounds : Rect2D;

    public function new() {
        addHeader();
    }

    public function bound( b : Rect2D, flipY: Bool, f : ImageFrame = null) {
        bounds = b;
        frame = ImageFrame.generateFrameOrDefault(f, bounds);
        @:privateAccess frame.flipY = flipY;

    }


    private function addHeader( ) {
        _buffer.add('<?xml version="1.0" encoding="UTF-8" standalone="no"?>\n');
        _buffer.add('<svg xmlns="http://www.w3.org/2000/svg" version="1.1">\n');
        _buffer.add('<defs>\n');
        _buffer.add('\t<marker\n');
        _buffer.add('\t\tid="arrow"\n');
        _buffer.add('\t\tviewBox="0 0 10 10"\n');
        _buffer.add('\t\trefX="5"\n');
        _buffer.add('\t\trefY="5"\n');
        _buffer.add('\t\tmarkerWidth="6"\n');
        _buffer.add('\t\tmarkerHeight="6"\n');
        _buffer.add('\t\torient="auto-start-reverse">\n');
        _buffer.add('\t<path d="M 0 0 L 10 5 L 0 10 z" />\n');
        _buffer.add('\t</marker>\n');
        _buffer.add('</defs>\n');
    }

    private function addFillStroke( attr : SVGAttributes ) {
        if (attr != null && attr.fill != null) {
            _buffer.add(' fill="${attr.fill}"');
        } else {
            _buffer.add(' fill="${defaultFill}"');
        }
        if (attr != null && attr.stroke != null) {
            _buffer.add(' stroke="${attr.stroke}"');
        } else {
            _buffer.add(' stroke="${defaultStroke}"');
        }
    }
    private function addStroke( attr : SVGAttributes ) {
        if (attr != null && attr.stroke != null) {
            _buffer.add(' stroke="${attr.stroke}"');
        } else {
            _buffer.add(' stroke="${defaultStroke}"');
        }
    }
    public function triangle( tri: Triangle2D, attr : SVGAttributes = null) {
        //'<polygon points="${ax},${ay} ${bx},${by} ${cx},${cy}" fill="${attr.fill}" stroke="${attr.stroke}"/>\n');
        _buffer.add('\t<polygon points="${frame.transformX(tri.a.x)},${frame.transformY(tri.a.y)} ${frame.transformX(tri.b.x)},${frame.transformY(tri.b.y)} ${frame.transformX(tri.c.x)},${frame.transformY(tri.c.y)}"');
        addFillStroke(attr);
        _buffer.add('/>\n');
    }
    public function polygon( points : Array<Point2D>, attr : SVGAttributes = null) {
        //'<polygon points="${ax},${ay} ${bx},${by} ${cx},${cy}" fill="${attr.fill}" stroke="${attr.stroke}"/>\n');

        _buffer.add('\t<polygon points="');
        for (p in points) {
            if (frame != null) {
                _buffer.add('${frame.transformX(p.x)},${frame.transformY(p.y)} ');
            } else  {
                _buffer.add('${p.x},${p.y} ');
            }
        }
        _buffer.add('"');
        addFillStroke(attr);
        _buffer.add('/>\n');
    }

    public function circle( center_x : Float, center_y: Float, radius : Float, attr : SVGAttributes ) {
        //'<circle cx="${cx}" cy="${cy}" r="${r}" fill="${attr.fill}" stroke="${attr.stroke}"/>\n');
        _buffer.add('\t<circle cx="${center_x}" cy="${center_y}" r="${radius}"');
        addFillStroke(attr);
        _buffer.add('/>\n');
    }

    public function line( start_x : Float, start_y : Float,end_x:Float, end_y:Float, attr : SVGAttributes ) {
        //'<line x1="${start.x}" y1="${start.y}" x2="${end.x}" y2="${end.y}" stroke="${attr.stroke}"/>\n');
        _buffer.add('\t<line x1="${start_x}" y1="${start_y}" x2="${end_x}" y2="${end_y}"');
        addStroke(attr);
        _buffer.add('/>\n');
    }

    public function text( text : String, position_x: Float, position_y:Float, attr : SVGAttributes ) {
        // svgContent.add('<text x="${center.x}" y="${center.y + 5}" text-anchor="middle" font-size="12px" font-family="Arial">${cell.key}[${Math.round(originalCenter.z / PRECISION)* PRECISION}]</text>\n');
        var font = attr.font != null ? attr.font : defaultFont;
        var halignment = attr.halignment != null ? attr.halignment : defaultHAlignment;
        _buffer.add('\t<text x="${position_x}" y="${position_y}" text-anchor="${halignment}" font-size="${attr.fontSize}px" font-family="${font}">${text}</text>\n');
    }

    public function lineArrow( start : Point2D, end_x:Float, end_y:Float, attr : SVGAttributes ) {
        //'<line x1="${start.x}" y1="${start.y}" x2="${end_x}" y2="${end_y}" stroke="${attr.stroke}" marker-end="url(#arrow)"/>\n');
        _buffer.add('\t<line x1="${start.x}" y1="${start.y}" x2="${end_x}" y2="${end_y}"');
        addStroke(attr);
        _buffer.add(' marker-end="url(#arrow)"/>\n');
    }

    public function finishAndWrite( path : String ) {
        _buffer.add('</svg>\n');
        File.saveContent(path, _buffer.toString());
    }

}