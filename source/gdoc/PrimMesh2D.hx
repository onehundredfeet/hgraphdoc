package gdoc;

abstract PrimMesh2D(Array<Prim2D>) from Prim2D to Prim2D {
    public function getSubdivided(connectivity: PrimConnectivity2D = null) : PrimMesh2D {
        if (connectivity == null) {
            connectivity = PrimConnectivity2D.fromPrims(this);
        }
        
        return null;
    }
}