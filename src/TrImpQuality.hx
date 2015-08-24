import vehjo.Vector;
typedef L = vehjo.LazyLambda;

class TrImpQuality {

	public var refLength( default, null ): Float;
	public var pathLength( default, null ): Float;
	public var eLength( default, null ): Float;
	public var qLength( default, null ): Float;
	public var eArea( default, null ): Float;
	public var qArea( default, null ): Float;
	public var eTrImp( default, null ): Float;
	public var qTrImp( default, null ): Float;

	public var quality( get_quality, never ): Float;
	function get_quality(): Float {
		return ( qLength + qArea + qTrImp )/3.;
	}

	public function new( ref: Iterable<Vector>, path: Iterable<Vector>, eTrImp: Float ) {
		refLength = perimeter( ref );
		pathLength = perimeter( path );

		eLength = pathLength - refLength;
		qLength = eLength/refLength;

		eArea = area( L.concat( path, reverse( ref ) ) );
		qArea = Math.sqrt( eArea )/refLength;

		this.eTrImp = eTrImp;
		qTrImp = eTrImp/refLength;
	}

	function reverse( x: Iterable<Vector> ): Iterable<Vector> {
		var res = new List();
		for ( p in x )
			res.add( p );
		return res;
	}

	function perimeter( x: Iterable<Vector> ): Float {
		var len = 0.;
		var prePt = null;
		for ( pt in x ) {
			if ( prePt != null ) {
				len += pt.sub( prePt ).mod();
			}
			prePt = pt;
		}
		return len;
	}

	function area( x: Iterable<Vector> ): Float {
		var a = 0.;
		var prePt: Vector = null;
		for ( pt in x ) {
			if ( prePt != null ) {
				a += prePt.x*pt.y - pt.x*prePt.y;
			}
			prePt = pt;
		}
		var pt = L.find( x, true );
		a += prePt.x*pt.y - pt.x*prePt.y;
		return .5*Math.abs( a );
	}

	public function toArray(): Array<Float> {
		return [ refLength, pathLength, eLength, qLength, eArea, qArea, eTrImp, qTrImp ];
	}

}

