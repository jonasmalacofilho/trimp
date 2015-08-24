import TextGeography;
import emmekit.*;
import haxe.io.Input;
import haxe.io.Output;
import vehjo.MathExtension;
import vehjo.Vector;
import vehjo.macro.Debug;
import vehjo.macro.Error;
private typedef L = vehjo.LazyLambda;
private typedef S = vehjo.sort.Heapsort;

class TrImp {

	public var path( default, null ): Array<Vertex>;
	public var cost( default, null ): Float;
	public var errorDist( default, null ): Float;
	public var graphDist( default, null ): Float;

	#if debug
	public static var _callback: Null<Int -> Void> = null;
	#end

	var dg: Digraph;
	var refLine: Array<Vector>;

	public function new( ref: Array<Vector>, dg: Digraph, errorWeight: Float, graphWeight: Float,
		?beginningCandidates: Iterable<Vertex>, ?endCandidades: Iterable<Vertex> ) {

		if ( beginningCandidates == null )
			beginningCandidates = L.lazy( dg.getVertices() );

		if ( endCandidades == null )
			endCandidades = L.lazy( dg.getVertices() );

		L.iter( L.lazy( dg.getVertices() ), {
			$x.clear();
		} );
		L.iter( L.lazy( dg.getArcs() ), {
			$x.clear();
			$x.cost = graphWeight*$x.len;
		} );

		L.iter( beginningCandidates, {
			$x.cost = 0.;
			$x.parent = $x;
			$x.lab = 0;
		} );

		for ( i in 0...ref.length ) {
			var pt = ref[i];
			trace( 'at point ' + ( i + 1 ) + ' ' + pt );

			L.iter( L.lazy( dg.getVertices() ), { // O( V )
				$x.curErrorDist = pt.sub( $x ).mod();
				$x.lab = 0;
				if ( $x.parent != null ) {
					$x.cost += errorWeight*$x.curErrorDist;
					$x.parent = $x;
				}
			} );

			if ( i < ref.length - 1 ) {

				#if debug dg.verbose = true; #end

				dg.bellmanFordRelaxation(); // ~ O( V*A )

				#if debug
				if ( dg.bellmanFordHasNegativeCycles() )
					break;
				dg.verbose = false;
				#end

			}

			L.iter( L.lazy( dg.getVertices() ), { // O( V )
				$x.oldParents.push( $x.parent );
				#if debug
				$x._graphDist.push( $x.graphDist );
				$x._errorDist.push( $x.errorDist );
				#end
			} );

			#if debug
			if ( _callback != null )
				_callback( i );
			#end

		}

		var t: Vertex = null;
		t = L.fold( endCandidades, ( $x.parent != null && ( $pre == null || $x.cost < $pre.cost ) ) ? $x : $pre, t );
		if ( t == null ) {
			trace( 'no path found' );
			return;
		}
		path = L.array( dg.rebuildPath( t ) );
		cost = t.cost;
		errorDist = t.errorDist;
		graphDist = t.graphDist;

		#if debug
		// trace( L.join( L.map( path, $x.i ), '-' ) );
		#end

	}

	public static function printStatus( msg: String ): Void {
		Sys.stderr().writeString( msg + '\n' );
	}

	public static function printMinorStatus( msg: String ): Void {
		Sys.stderr().writeString( '|- ' + msg + '\n' );
	}

	public static function printError( e: Dynamic, ?stackTrace=false ): Void {
		Sys.stderr().writeString( 'Error: "' + e + '"\n' );

		#if debug
		if ( stackTrace )
			Sys.stderr().writeString( haxe.CallStack.toString( haxe.CallStack.exceptionStack() ) + '\n' );
		#end
	}

	public static function nearLinks( s: Scenario, ref: Array<Vector> ): Iterable<Link> {
		printMinorStatus( 'searching for near links' );

		#if debug
		if ( _testDrawNearBBoxes ) {
			DirtyKml.beginFolder( kmlOutput, "_testDrawNearBBoxes" );
		}
		#end

		var ks = new Map();
		for ( i in 1...ref.length ) {
			var prePt = ref[i - 1];
			var pt = ref[i];

			var min = new Vector( Math.min( prePt.x, pt.x ), Math.min( prePt.y, pt.y ) );
			var max = new Vector( Math.max( prePt.x, pt.x ), Math.max( prePt.y, pt.y ) );
			var del = max.sub( min );
			var incr = new Vector( Math.max( del.x, del.y )*1., Math.max( del.x, del.y )*1. );

			var del2 = del.sum( incr.scale( 2. ) ).scale( _testBBoxesSizeFactor );
			var min2 = min.sub( del2.sub( del ).scale( .5 ) );
			var max2 = min2.sum( del2 );

			#if debug
			if ( _testDrawNearBBoxes ) {
				DirtyKml.addLineString( kmlOutput, _currentLine + ':' + i,
					[ min2, min2.sum( new Vector( del2.x, 0. ) ), max2, min2.sum( new Vector( 0., del2.y ) ), min2 ],
					null, .2, null, null, false );
			}
			#end

			for ( k in s.link_search_rectangle( min2.x, min2.y, max2.x, max2.y ) )
				if ( !ks.exists( k.key ) )
					ks.set( k.key, k );
		}

		#if debug
		if ( _testDrawNearBBoxes ) {
			DirtyKml.endFolder( kmlOutput );
		}
		if ( _testDrawNearLinks ) {
			DirtyKml.beginFolder( kmlOutput, "_testDrawNearLinks" );
			L.iter( ks, DirtyKml.addLineString( kmlOutput, $x.key, L.map( $x.full_shape(), cast( $x, Vector ) ),
				null, 1., null, null, false ) );
			DirtyKml.endFolder( kmlOutput );
		}
		#end

		printMinorStatus( 'done searching for near links' );
		return ks;
	}

	static var cacheKey: String = null;
	static var cacheMode: String = null;
	static var cacheDigraph: Digraph = null;
	public static function buildDigraph( key: String, s: Scenario, ref: Array<Vector>, ?mode: String, ?wrongModeWeight: Null<Float> ): Digraph {
		if ( cacheKey != key || cacheMode != mode ) {
			printMinorStatus( 'building a new digraph' );
			var dg = new Digraph();
			for ( k in nearLinks( s, ref ) ) {
				var lenWeight = 1.;
				if ( mode != null && !k.has_any_of_modes( mode ) ) {
					if ( wrongModeWeight != null )
						lenWeight = wrongModeWeight;
					else
						continue;
				}

				var v = dg.getVertex( k.fr.i );
				if ( v == null )
					v = dg.addVertex( k.fr.i, k.fr.xi, k.fr.yi );

				var w = dg.getVertex( k.to.i );
				if ( w == null )
					w = dg.addVertex( k.to.i, k.to.xi, k.to.yi );

				var len = 0.;
				var prePt: ShapePoint = null;
				for ( pt in k.full_shape() ) {
					if ( prePt != null )
						len += prePt.sub( pt ).mod();
					prePt = pt;
				}

				dg.addArc( v, w, len*lenWeight );
			}

			cacheKey = key;
			cacheMode = mode;
			cacheDigraph = dg;
			printMinorStatus( 'done building a V,A=' + dg.nV + ',' + dg.nA + ' digraph' );
		}
		return cacheDigraph;
	}

	public static function reverseArray<A>( x: Array<A> ): Array<A> {
		var y = [];
		for ( i in 0...x.length )
			y.push( x[x.length - 1 - i] );
		return y;
	}

	public static function compressPolyline( x: Array<Vector>, maxAngle: Float ): Array<Vector> {
		var y = x.copy();
		while ( true ) {
			var i = -1;
			var minAngle = Math.POSITIVE_INFINITY;
			for ( j in 1...y.length - 1 ) {
				var v = y[j].sub( y[j - 1] );
				var w = y[j + 1].sub( y[j] );
				var dp = v.dotProduct( w );
				var angle = Math.abs( Math.acos( dp / v.mod() / w.mod() ) );
				// trace( angle );
				if ( angle < minAngle ) {
					minAngle = angle;
					i = j;
				}
			}
			if ( i == -1 )
				break;
			if ( minAngle <= vehjo.MathExtension.to_radians( maxAngle ) )
				y = y.slice( 0, i ).concat( y.slice( i + 1 ) );
			else
				break;
		}
		return y;
	}

	public static function getDetailedPath( scen: Scenario, path: Iterable<Vertex> ): Iterable<Vector> {
		var detailedPath = [];
		var pv = null;
		for ( v in path ) {
			if ( pv != null ) {
				if ( detailedPath.length > 0 )
					detailedPath.pop();
				var k = scen.link_get( pv.i, v.i );
				detailedPath = detailedPath.concat( L.array( k.full_shape() ) );
			}
			pv = v;
		}
		return detailedPath;
	}

	// Testing options
	static var _testOnlySome: Array<String> = null;
	static var _testBBoxesSizeFactor: Float = 1.;

	#if debug
	static var _currentLine: String = null;

	static var _testListLines = false;
	static var _testSkipNet = false;
	static var _testSkipOut = false;
	static var _testHalves = false;

	static var _testDrawNearBBoxes: Bool = false;
	static var _testDrawNearLinks: Bool = false;
	static var _testDrawGraphCosts: Bool = false;
	#end

	// Kml output
	static var kmlOutput: Output = null;

	static inline var DEFAULT_ERROR_WEIGHT = 1.;
	static inline var DEFAULT_GRAPH_WEIGHT = 0.;

	public static function main() {

		var sw = new vehjo.StopWatch();

		haxe.Log.trace = function ( d, ?p ) printMinorStatus( d );

		// Input and Output options

		// Input comes from stdin
		var trInp = Sys.stdin();
		// Alternative transit lines names
		var trInpNames: vehjo.format.csv.Reader = null;
		// Line settings
		var mode: Null<String> = null;
		var veh: Null<Int> = null;
		var hdw: Null<Float> = null;
		var speed: Null<Float> = null;
		// Try reversed?
		var tryReversed = false;

		// Output goes to stdout
		var fout = Sys.stdout();

		// Additional output
		// Quality info
		var qualityOut: vehjo.format.csv.Writer = null;

		// Network input
		var netInp: Array<Input> = [];
		var netCacheInp: Input = null;
		var netCacheOut: Output = null;

		// Algorithm configuration

		// Reference line compression
		var compressionMaxAngle: Null<Float> = null;
		// Error distance weight
		var errorWeight = [ DEFAULT_ERROR_WEIGHT ];
		// Graph distance weight
		var graphWeight = [ DEFAULT_GRAPH_WEIGHT ];
		// Endpoint tolerance (in network lenght units)
		var endpointTolerance = Math.POSITIVE_INFINITY;
		// Length weight for links without any compatible modes
		var wrongModeWeight = null;

		// Argument processing
		var args = Lambda.list( Sys.args().length > 0 ? Sys.args() : [ '--help' ] );
		while ( !args.isEmpty() ) {
			var a = args.pop();
			switch ( a ) {

				// Network
				case '--net':
					Error.throwIf( args.length < 1 );
					var fpath = args.pop();
					Error.throwIf( !sys.FileSystem.exists( fpath ), fpath + ' does not exist' );
					netInp.push( sys.io.File.read( fpath, false ) );
				case '--cache':
					Error.throwIf( args.length < 1 );
					var fpath = args.pop();
					if ( sys.FileSystem.exists( fpath ) )
						netCacheInp = sys.io.File.read( fpath, false );
					else
						netCacheOut = sys.io.File.write( fpath, false );

				// Input
				case '--names':
					Error.throwIf( args.length < 1 );
					var fpath = args.pop();
					Error.throwIf( !sys.FileSystem.exists( fpath ), fpath + ' does not exist' );
					trInpNames = new vehjo.format.csv.Reader( sys.io.File.read( fpath, false ) );
				case '--mode':
					Error.throwIf( args.length < 1 );
					mode = args.pop();
					Error.throwIf( mode.length != 1 );
				case '--veh':
					Error.throwIf( args.length < 1 );
					veh = Std.parseInt( args.pop() );
					Error.throwIf( veh < 1 || veh > 999 );
				case '--hdw':
					Error.throwIf( args.length < 1 );
					hdw = Std.parseFloat( args.pop() );
					Error.throwIf( hdw < 0.01 || hdw > 999.99 );
				case '--speed':
					Error.throwIf( args.length < 1 );
					speed = Std.parseFloat( args.pop() );
					Error.throwIf( speed < 0.01 || speed > 999.99 );
				case '--try-reversed':
					tryReversed = true;

				// Algorithm configuration
				case '--compress-ref':
					Error.throwIf( args.length < 1 );
					compressionMaxAngle = Std.parseFloat( args.pop() );
				case '--error-weight':
					Error.throwIf( args.length < 1 );
					errorWeight = L.array( L.map( args.pop().split( ',' ), Std.parseFloat( $x ) ) );
				case '--graph-weight':
					Error.throwIf( args.length < 1 );
					graphWeight = L.array( L.map( args.pop().split( ',' ), Std.parseFloat( $x ) ) );
				case '--endpoint-tol':
					Error.throwIf( args.length < 1 );
					endpointTolerance = Std.parseFloat( args.pop() );
				case '--wrong-mode-weight':
					Error.throwIf( args.length < 1 );
					wrongModeWeight = Std.parseFloat( args.pop() );


				// Additional output
				case '--quality':
					Error.throwIf( args.length < 1 );
					qualityOut = new vehjo.format.csv.Writer( sys.io.File.write( args.pop(), false ) );
				case '--kml-output':
					Error.throwIf( args.length < 1 );
					kmlOutput = sys.io.File.write( args.pop(), false );
					DirtyKml.begin( kmlOutput, a, true );

				// Other
				case '--no-traces': haxe.Log.trace = function ( d, ?p ) {};

				// Testing options
				case '--test-only-some':
					Error.throwIf( args.length < 1 );
					_testOnlySome = _testOnlySome != null ? _testOnlySome.concat( [ args.pop() ] ) : [ args.pop() ];
				case '--test-bboxes-size-factor':
					Error.throwIf( args.length < 1 );
					_testBBoxesSizeFactor = Std.parseFloat( args.pop() );

				#if debug
				case '--test-list-lines': _testListLines = true;
				case '--test-skip-net': _testSkipNet = true;
				case '--test-skip-out': _testSkipOut = true;
				case '--test-halves': _testHalves = true;

				// Testing additional/optional outputs
				case '--test-draw-near-bboxes':
					_testDrawNearBBoxes = true;
				case '--test-draw-near-links':
					_testDrawNearLinks = true;
				case '--test-draw-graph-costs':
					_testDrawGraphCosts = true;

				#end

				case '--help':
					Sys.println( 'usage: input comes from stdin in Text/Geography and output goes in Emme Free Format lines file to stdout' );
					Sys.println( 'options:' );

					Sys.println( '\n\t// Network input' );
					Sys.println( '\t--net <path to Emme Free Format>: used to read the base network (one per option)' );
					Sys.println( '\t[--cache <path to Mhx cache>]: optional Mhx cache' );

					Sys.println( '\n\t// Data input' );
					Sys.println( '\t--mode <mode>: mode for all lines, must be an Emme transit mode' );
					Sys.println( '\t--veh <no>: vehicle type for all lines, must be a compatible Emme vehicle' );
					Sys.println( '\t--hdw <headway in minutes>: default headway for all lines' );
					Sys.println( '\t--speed <speed in km/h>: default speed for all lines' );
					Sys.println( '\t[--names <path to CSV with "ID" and "Name">]: optional names for reference lines' );
					Sys.println( '\t[--try-reversed]: also attempt to imported reversed reference lines' );

					Sys.println( '\n\t// Additional output' );
					Sys.println( '\t[--quality <path for CSV>]: quality estimates for imported lines' );
					Sys.println( '\t[--kml-output <path for KML>]: draw reference lines and best paths' );

					Sys.println( '\n\t// Algorithm configuration' );
					Sys.println( '\t[--compress-ref <maximum angle between segments that can be lost>]: default is no compression' );
					Sys.println( '\t[--error-weight <comma-separated desired weights for error distances>]: default is ' + DEFAULT_ERROR_WEIGHT );
					Sys.println( '\t[--graph-weight <comma-separated desired weights for distances on the graph>]: default is ' + DEFAULT_GRAPH_WEIGHT );
					Sys.println( '\t[--endpoint-tol <maximum error distance allowed for endpoints>]: default is +oo' );
					Sys.println( '\t[--wrong-mode-weigth <arc len weight>]: default is +oo' );

					Sys.println( '\n\t// Other' );
					Sys.println( '\t[--no-traces]: suppress detailed traces' );

					Sys.println( '\n\t// Debugging options' );
					Sys.println( '\t[--test-only-some <name>]: only attempt to import these lines (one per option)' );
					#if debug
					Sys.println( '\t[--test-list-lines]: show line names for what has been read' );
					Sys.println( '\t[--test-skip-net]: do not load a network' );
					Sys.println( '\t[--test-skip-out]: do not output a EFF lines file' );
					Sys.println( '\t[--test-halves]: split the reference in two halves and test them as separate lines' );

					Sys.println( '\n\t// Graphical debugging (requires --kml-output)' );
					Sys.println( '\t[--test-draw-near-bboxes]: draw boundings boxes used on digraph building' );
					Sys.println( '\t[--test-draw-near-links]: draw links near to the reference line' );
					Sys.println( '\t[--test-draw-graph-costs]: draw costs at each vertex' );
					#end

					Sys.exit( Sys.args().length == 1 ? 0 : 1 );

				default: throw 'unknown option ' + a;
			}
		}

		#if debug
		if ( _testSkipNet )
			_testSkipOut = true;
		Error.throwIf( _testDrawNearBBoxes == true && kmlOutput == null );
		Error.throwIf( _testDrawNearLinks == true && kmlOutput == null );
		Error.throwIf( _testDrawGraphCosts == true && kmlOutput == null );
		#end

		#if debug if ( !_testSkipOut ) #end {
			Error.throwIf( mode == null );
			Error.throwIf( veh == null );
			Error.throwIf( hdw == null );
			Error.throwIf( speed == null );
		}

		try {

			printStatus( 'Loading network' );
			var s = new Scenario();
			s.distance = function ( ax, ay, bx, by ) return 1e-3*MathExtension.earth_distance_haversine( ay, ax, by, bx );
			#if debug if ( !_testSkipNet ) #end {
				if ( netCacheInp == null || L.holds( Type.getClassFields( Scenario ), $x!='SERIALIZATION_FORMAT' ) ) {
					// Error.throwIf( netInp.length == 0 );
					L.iter( netInp, s.eff_read( $x ).close() );
					if ( netCacheOut != null && L.holdsOnce( Type.getClassFields( Scenario ), $x=='SERIALIZATION_FORMAT' ) ) {
						printMinorStatus( 'serializing cached network' );
						var hs = new haxe.Serializer();
						hs.useEnumIndex = true;
						var dist = s.distance;
						s.distance = null;
						hs.serialize( s );
						s.distance = dist;
						printMinorStatus( 'dumping serialized data to cache file' );
						netCacheOut.writeString( hs.toString() );
						netCacheOut.close();
					}
				}
				else {
					printMinorStatus( 'unserializing cached network' );
					s = haxe.Unserializer.run( netCacheInp.readAll().toString() );
					s.distance = function ( ax, ay, bx, by ) return 1e-3*MathExtension.earth_distance_haversine( ay, ax, by, bx );
				}
			}

			printStatus( 'Loading transit lines to import' );
			var geo = TextGeographyLinks.read( trInp );
			trInp.close();

			printStatus( 'Loading transit lines names' );
			var geoNames = new Map();
			if ( trInpNames == null ) {
				printMinorStatus( 'skipped' );
				L.iter( geo, geoNames.set( $x.id, Std.string( $x.id ) ) );
			}
			else {
				var csv = trInpNames.readData( true );
				L.iter( csv, if ( geo.exists( Std.parseInt( $x.ID ) ) ) geoNames.set( Std.parseInt( $x.ID ), $x.Name ) );
				trInpNames.close();
			}

			if ( _testOnlySome != null )
				printStatus( 'Debug filter active: "' + _testOnlySome.join ( '", "' ) + '"' );

			#if debug
			if ( _testListLines )
				L.iter( L.lazy( geoNames.keys() ), printMinorStatus( geoNames.get( $x ) + '(' + $x + ')' ) );
			#end

			if ( qualityOut != null )
				qualityOut.writeRecord( 'Line|RefLength|PathLength|ELength|QLength|EArea|QArea|ETrImp|QTrImp'.split( '|' ) );

			var orderedLines = S.heapsort(
			  L.filter( geo, geoNames.exists( $x.id ) )
			  , function ( a, b )
			  		return geoNames.get( b.id ) < geoNames.get( a.id )
			  );

			var lineNo = 0;
			for ( line in orderedLines ) {
				var lineName = geoNames.get( line.id );
				lineNo++;

				if ( _testOnlySome != null && !L.holdsOnce( _testOnlySome, $x == lineName ) )
					continue;

				#if debug
				for ( half in 0...( _testHalves ? 2 : 1 ) ) {
					if ( _testHalves )
						lineName = geoNames.get( line.id ) + ( half == 0 ? 'AB' : 'BA' );
					_currentLine = lineName;
				#end

				printStatus( 'Attempting to import line ' + lineName + ' (' + lineNo + '/' + orderedLines.length + ')' );

				var ref = L.array( L.map( L.concat( L.lazyConcat( [ line.from ], line.inflections ), [ line.to ] ), cast( $x, Vector ) ) );

				if ( kmlOutput != null ) {
					DirtyKml.beginFolder( kmlOutput, lineName );
					DirtyKml.addLineString( kmlOutput, 'shape', ref, 'ffa0a0ff', 4., null, null, true );
					DirtyKml.addPoint( kmlOutput, 'beginning', ref[0], null, 0.8, null, 0.8, null, true );
					DirtyKml.addPoint( kmlOutput, 'end', ref[ref.length - 1], null, 0.8, null, 0.8, null, true );
					#if debug
					if ( _testHalves )
						DirtyKml.addPoint( kmlOutput, 'middle', ref[Std.int( ref.length/2 )], null, 0.8, null, 0.8, null, true );
					#end
				}

				var dg = buildDigraph( lineName, s, ref, mode );

				#if debug
				if ( _testHalves )
					ref = ( half == 0 ) ? ref.slice( 0, Std.int( ref.length/2 ) + 1 ) : ref.slice( Std.int( ref.length/2 ) );
				#end

				if ( compressionMaxAngle != null ) {
					var oldLen = ref.length;
					ref = compressPolyline( ref, compressionMaxAngle );
					printMinorStatus( 'reference line was compressed, compression ratio = ' + .1*Std.int( 1000.*ref.length/oldLen ) + '% (was ' + oldLen + ', now is ' + ref.length + ')' );
					if ( kmlOutput != null )
						DirtyKml.addLineString( kmlOutput, 'compressed shape', ref, 'ffa0a0ff', 4., null, null, false );
				}

				for ( rev in 0...( tryReversed ? 2 : 1 ) ) {
					if ( rev != 0 ) {
						lineName += ' Rev';
						printMinorStatus( 'retrying with reversed reference' );
						#if debug
						_currentLine = lineName;
						#end

						ref = reverseArray( ref );
					}

					var beginningCandidates: Iterable<Vertex> = null;
					var endCandidates: Iterable<Vertex> = null;
					if ( Math.isFinite( endpointTolerance ) ) {
						beginningCandidates = L.filter( L.map( s.node_search_radius( ref[0].x, ref[0].y, endpointTolerance ), dg.getVertex( $x.i ) ), $x != null );
						endCandidates = L.filter( L.map( s.node_search_radius( ref[ref.length - 1].x, ref[ref.length - 1].y, endpointTolerance ), dg.getVertex( $x.i ) ), $x != null );
					}

					DirtyKml.beginFolder( kmlOutput, rev == 0 ? 'paths:direct' : 'paths:reversed', true );

					for ( ew in errorWeight ) for ( gw in graphWeight ) {

						var ratio = gw/ew;
						var pseudoLineName = lineName + ' ' + vehjo.NumberPrinter.printDecimal( ratio, 0, 3 );
						Debug.assert( pseudoLineName );
						printMinorStatus( 'running TrImp with graphWeight/errorWeight = ' + ratio );
						var cand = new TrImp( ref, dg, ew, gw, beginningCandidates, endCandidates );

						#if debug
						if ( _testDrawGraphCosts ) {
							trace( 'drawing costs at vertices' );

							var minCost = Math.POSITIVE_INFINITY, maxCost = Math.NEGATIVE_INFINITY;
							for ( v in dg.getVertices() )
								if ( v.parent != null ) {
									if ( v.cost < minCost )
										minCost = v.cost;
									if ( v.cost > maxCost )
										maxCost = v.cost;
								}

							DirtyKml.beginFolder( kmlOutput, "_testDrawGraphCosts" );
							for ( v in dg.getVertices() )
								if ( v.parent != null )
									DirtyKml.addPoint( kmlOutput,
										v.i + ':' + v.cost, v,
										'#dfcfcf' + StringTools.hex( Std.int( 0xff*( maxCost - v.cost )/( maxCost - minCost ) ), 2 ),
										.4, 'http://maps.google.com/mapfiles/kml/paddle/wht-blank.png',
										0., null, false,
										'<b>i = ' + v.i + '</b><br/>cost = ' + v.cost + '<br/>errorDist = ' + v.errorDist + '<br/>graphDist = ' + v.graphDist );
							DirtyKml.endFolder( kmlOutput );
						}
						#end

						if ( cand.path == null ) {
							printMinorStatus( 'no path found' );
							if ( qualityOut != null )
								qualityOut.writeRecord( [ pseudoLineName, 'no path found' ] );
							continue;
						}

						printMinorStatus( 'generating a detailed path' );
						var detailedPath = getDetailedPath( s, cand.path );

						#if debug if ( !_testSkipOut ) #end {
							printMinorStatus( 'loading line into scenario' );
							var line = s.line_add( scenarioLineName( s, pseudoLineName ), mode, veh, hdw, speed, pseudoLineName );
							L.iter( cand.path, s.segment_push( line.line, $x.i, true, true ) );
						}

						if ( qualityOut != null ) {
							printMinorStatus( 'analyzing the generated path' );
							var candQuality = new TrImpQuality( ref, detailedPath, cand.errorDist );
							qualityOut.writeRecord( [ pseudoLineName ].concat( L.array( L.map( candQuality.toArray(), Std.string( $x ) ) ) ) );
						}

						if ( kmlOutput != null )
							DirtyKml.addLineString( kmlOutput, vehjo.NumberPrinter.printDecimal( ratio, 0, 3 ), detailedPath, '#ffa0ffa0', 3. );

					} // ew,gw

					DirtyKml.endFolder( kmlOutput );

				}

				if ( kmlOutput != null )
					DirtyKml.endFolder( kmlOutput );

				#if debug
				} // end of for half in ...
				#end

			} // end of for line in

			#if debug if ( !_testSkipNet && !_testSkipOut ) #end {
				s.eff_write_lines( fout ).close();
			}

		}
		catch ( e: Dynamic ) {
			printError( e, true );
		}

		if ( qualityOut != null )
			qualityOut.close();
		if ( kmlOutput != null  ) {
			DirtyKml.end( kmlOutput );
			kmlOutput.close();
		}

		printStatus( 'Took ' + sw.partial() + ' seconds' );

	}

	static function scenarioLineName( s: Scenario, lineName: String ): String {
		var name = '';
		do {
			if ( name != '' )
				printMinorStatus( 'line name "' + name + '" already exists' );
			var sha1 = haxe.crypto.Sha1.encode( lineName + name );
			name = sha1.substr( 0, 2 ) + sha1.substr( 36, 4 );
			Debug.assert( name );
		} while ( s.line_exists( name ) );
		return name;
	}

}

