import vehjo.Lam;
import vehjo.macro.Debug;
import vehjo.macro.Error;
import vehjo.sort.Heapsort;
import vehjo.Vector;
using Std;

class TextGeographyLinks {

	var objs: Map<Int, TextGeographyLink>;

	public function new() {
		objs = new Map();
	}

	public function addLink( link: TextGeographyLink ) {
		Debug.assertTrue( !objs.exists( link.id ) );
		if ( objs.exists( link.id ) ) {
			var existingLink = objs.get( link.id );
			var inflections = existingLink.inflections.concat( [ existingLink.to ] ).concat( [ link.from ] ).concat( link.inflections );
			objs.set( link.id, new TextGeographyLink( link.id, existingLink.from, link.to, inflections ) );
		}
		else
			objs.set( link.id, link );
	}

	public function write( out: haxe.io.Output ): Void {
		var sobjs = Heapsort.heapsort( objs, function ( a, b ) return b.id<a.id );
		for ( x in sobjs )
			out.writeString( x.write()+'\n' );
	}

	public static function read( inp: haxe.io.Input ): TextGeographyLinks {
		var tgl = new TextGeographyLinks();

		while ( true ) try {
			var d = inp.readLine().split( ',' );

			var pts = [];
			for ( i in 0...d[1].parseInt() )
				pts.push( new Point( d[i*2+2].parseFloat(), d[i*2+3].parseFloat() ) );

			var x = new TextGeographyLink( d[0].parseInt(), pts[0], pts[pts.length-1], pts.slice( 1, -1 ) );
			tgl.objs.set( x.id, x );
		}
		catch ( e: haxe.io.Eof ) {
			break;
		}

		return tgl;
	}

	public function getLink( id: Int ): TextGeographyLink {
		return objs.get( id );
	}

	public function iterator(): Iterator<TextGeographyLink> {
		return objs.iterator();
	}

	public function exists( id: Int ): Bool {
		return objs.exists( id );
	}

}

class TextGeographyLink {

	public var id( default, null ): Int;
	public var from( default, null ): Point;
	public var to( default, null ): Point;
	public var inflections( default, null ): Array<Point>;

	public function new( id: Int, from: Point, to: Point, inflections: Array<Point> ) {
		this.id = id;
		this.from = from;
		this.to = to;
		this.inflections = inflections;
	}

	public function write(): String {
		Error.throwIf( inflections.length + 2 >= 700 ); // TODO: handle this
		return '$id,${inflections.length+2},' +
			Lam.map( [ from ].concat( inflections ).concat( [ to ] ), function( x ) return x.geoWrite() ).join( ',' );
	}

}

class Point extends Vector {

	public function new( x, y ) {
		super( x, y );
	}

	public function geoWrite(): String {
		return '$x,$y';
	}

}

