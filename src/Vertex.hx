import vehjo.Vector;
private typedef L = vehjo.LazyLambda;

class Vertex extends Vector {

	public var i( default, null ): Int;

	public var curErrorDist: Float;

	public var cost: Float;
	public var parent: Vertex;
	public var oldParents( default, null ): Array<Vertex>;

	public var graphDist: Float; // acc on path
	public var errorDist: Float; // acc on path

	#if debug
	public var _graphDist( default, null ): Array<Float>;
	public var _errorDist( default, null ): Array<Float>;
	#end

	public var arcsFrom: Array<Arc>;
	public var lab: Int;

	public function new( i: Int, x: Float, y: Float ) {
		super( x, y );
		arcsFrom = [];
		this.i = i;
	}

	public function clear(): Void {
		curErrorDist = 0.;
		lab = -1;

		cost = Math.POSITIVE_INFINITY;
		parent = null;
		oldParents = [];

		graphDist = 0.;
		errorDist = 0.;

		#if debug
		_graphDist = [];
		_errorDist = [];
		#end
	}

	override public function toString(): String {
		return 'Vertex { i: $i, cost: $cost, parent: ${parent != null ? Std.string( parent.i ) : "_"} }';
	}

	public function toHtml(): String {
		#if debug
		return '<b>Vertex $i</b><br/>cost = $cost<br/>parents = ${L.join( L.map( oldParents.concat( [ parent ] ), "(" + $x.i + "   " + $x._graphDist[$i] + "   " + $x._errorDist[$i] + ")" ), ",<br/>" )}<br/>graphDist = $graphDist<br/>errorDist = $errorDist<br/>';
		#else
		return '<b>Vertex $i</b><br/>cost = $cost<br/>parents = ${L.join( L.map( oldParents.concat( [ parent ] ), $x.i ), ", " )}<br/>graphDist = $graphDist<br/>errorDist = $errorDist<br/>';
		#end
	}

}

