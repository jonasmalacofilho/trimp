class Arc {

	public var v( default, null ): Vertex;
	public var w( default, null ): Vertex;
	public var cost: Float;
	public var len: Float;

	public function new( v: Vertex, w: Vertex, len: Float ) {
		this.v = v;
		v.arcsFrom.push( this );
		this.w = w;
		this.len = len;
	}

	public function clear() {
		cost = Math.POSITIVE_INFINITY;
	}

}

