package gdoc;

import gdoc.Random;
import hvector.Float2;

abstract Random2D(Random) {
    public inline function new() {
        this = new Random();
    }
    public inline function point2() : Float2 {
        return new Float2(this.random(), this.random());
    }

    public inline function point2Scaled(s : Float) : Float2 {
        return new Float2(this.random() * s, this.random() * s);
    }

    public inline function unitDisc() : Float2 {
        var theta = this.random2Pi();
        // Generate a random radius with proper scaling to ensure uniform distribution over the disc area
        var r = Math.sqrt(this.random());
        return new Float2(r * Math.cos(theta), r * Math.sin(theta));
    }
    
    public inline function disc(radius : Float) : Float2 {
        var theta = this.random2Pi();
        // Generate a random radius with proper scaling to ensure uniform distribution over the disc area
        var r = Math.sqrt(this.random()) * radius;
        return new Float2(r * Math.cos(theta), r * Math.sin(theta));
    }

    // disc band
    public function annulus(innerRadius:Float, outerRadius:Float): Float2 {
        var theta = this.random2Pi();

        // Generate a random radius with proper scaling to ensure uniform distribution over the annulus area
        final innerRadiusSquared = innerRadius * innerRadius;
        var rSquared = this.random() * (outerRadius * outerRadius - innerRadiusSquared) + innerRadiusSquared;
        var r = Math.sqrt(rSquared);

        return new Float2(r * Math.cos(theta), r * Math.sin(theta));
    }
}
 