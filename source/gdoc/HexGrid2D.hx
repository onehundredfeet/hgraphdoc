package gdoc;

import gdoc.Point2D;
import gdoc.Rect2D;

class HexGrid2D {
    static function pointsOnRect(bounds:Rect2D, radius:Float, perturbation:Float, random:Random):Array<Point2D> {
        var points:Array<Point2D> = [];
        var rowHeight = radius * Math.sqrt(3);

        var cols = Math.ceil(bounds.width / radius);
        var rows = Math.ceil(bounds.height / rowHeight);

        for (i in 0...cols) {
            for (j in 0...rows) {
                var x = i * radius * 1.5 + bounds.xmin;
                var y = j * rowHeight + bounds.ymin;

                if (i % 2 == 1) {
                    y += rowHeight / 2;
                }

                var perturbedX = x + (random.random() * 2 - 1) * perturbation;
                var perturbedY = y + (random.random() * 2 - 1) * perturbation;

                // Note - this may cull too many points, may need to expand bounds or provide otions
                if (perturbedX >= bounds.xmin && perturbedX < bounds.xmax && perturbedY >= bounds.ymin && perturbedY < bounds.ymax) {
                    points.push(new Point2D(perturbedX, perturbedY));
                }
            }
        }

        return points;
    }
}
