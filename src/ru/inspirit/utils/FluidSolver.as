package ru.inspirit.utils 
{
	/***********************************************************************
 
	* This is a class for solving real-time fluid dynamics simulations based on Navier-Stokes equations 
	* and code from Jos Stam's paper "Real-Time Fluid Dynamics for Games" http://www.dgp.toronto.edu/people/stam/reality/Research/pdf/GDC03.pdf
	* Other useful resources and implementations I looked at while building this lib: 
	* Mike Ash (C) - http://mikeash.com/?page=pyblog/fluid-simulation-for-dummies.html
	* Alexander McKenzie (Java) - http://www.multires.caltech.edu/teaching/demos/java/stablefluids.htm
	* Pierluigi Pesenti (AS3 port of Alexander's) - http://blog.oaxoa.com/2008/01/21/actionscript-3-fluids-simulation/
	* Gustav Taxen (C) - http://www.nada.kth.se/~gustavt/fluids/
	* Dave Wallin (C++) - http://nuigroup.com/touchlib/ (uses portions from Gustav's)
	
	/***********************************************************************
 
	Copyright (c) 2008, 2009, Memo Akten, www.memo.tv
	*** The Mega Super Awesome Visuals Company ***

	/**
	 * AS3 Port
	 * @author Eugene Zatepyakin
	 * @link http://blog.inspirit.ru/?p=248
	 * @link http://code.google.com/p/in-spirit/source/browse/#svn/trunk/projects/FluidSolver
	 */
	public final class FluidSolver 
	{
		public static var FLUID_DEFAULT_NX:Number						= 50;
		public static var FLUID_DEFAULT_NY:Number						= 50;
		public static var FLUID_DEFAULT_DT:Number						= 1.0;
		public static var FLUID_DEFAULT_VISC:Number						= 0.0001;
		public static var FLUID_DEFAULT_COLOR_DIFFUSION:Number 			= 0.0;
		public static var FLUID_DEFAULT_FADESPEED:Number				= 0.6;
		public static var FLUID_DEFAULT_SOLVER_ITERATIONS:int			= 40;
		public static var FLUID_DEFAULT_VORTICITY_CONFINEMENT:Boolean 	= false;
	
		//USED FOR COLOR
		public var r:Vector.<Number>;
		public var g:Vector.<Number>;
		public var b:Vector.<Number>;
		
		//USED FOR FLUID
		public var u:Vector.<Number>;
		public var v:Vector.<Number>;
	
		//PREVIOUS VALUES
		public var rOld:Vector.<Number>;
		public var gOld:Vector.<Number>;
		public var bOld:Vector.<Number>;
		
		public var uOld:Vector.<Number>;
		public var vOld:Vector.<Number>;
		
		//NO CLUE
		public var curl_abs:Vector.<Number>;
		public var curl_orig:Vector.<Number>;
		
		//WIDTH/HEIGHT OF FLUID
		public var width:int;
		public var height:int;
		
		public var numCells:int;
		
		protected var _NX:int, _NY:int, _NX2:int, _NY2:int;
		protected var _invNumCells:Number;
		protected var _dt:Number;
		protected var _isRGB:Boolean;				// for monochrome, only update r
		protected var _solverIterations:int;
		protected var _colorDiffusion:Number;
		protected var _doVorticityConfinement:Boolean;
		
		protected var wrap_x:Boolean = false;
		protected var wrap_y:Boolean = false;
		
		protected var _visc:Number;
		protected var _fadeSpeed:Number;
		
		protected var _tmp:Vector.<Number>;
		
		protected var _avgDensity:Number;			// this will hold the average color of the last frame (how full it is)
		protected var _uniformity:Number;			// this will hold the uniformity of the last frame (how uniform the color is);
		protected var _avgSpeed:Number;
		
		public function FluidSolver(NX:int, NY:int)
		{
			setup(NX, NY);
		}
		
		public function setup(NX:int, NY:int):void
		{
			_dt = FLUID_DEFAULT_DT;
			_fadeSpeed = FLUID_DEFAULT_FADESPEED;
			_solverIterations = FLUID_DEFAULT_SOLVER_ITERATIONS;
			_colorDiffusion = FLUID_DEFAULT_COLOR_DIFFUSION;
			_doVorticityConfinement = FLUID_DEFAULT_VORTICITY_CONFINEMENT;
			
			_NX = NX;
			_NY = NY;
			_NX2 = _NX + 2;
			_NY2 = _NY + 2;
			
			numCells = _NX2 * _NY2;
			
			_invNumCells = 1.0 / numCells;
			
			width = _NX2;
			height = _NY2;
			
			_isRGB = false;
			
			reset();
		}
		
		public function reset():void 
		{			
			const fixed:Boolean = false;
			
			r    = new Vector.<Number>(numCells, fixed);
			rOld = new Vector.<Number>(numCells, fixed);
			
			g    = new Vector.<Number>(numCells, fixed);
			gOld = new Vector.<Number>(numCells, fixed);
			
			b    = new Vector.<Number>(numCells, fixed);
			bOld = new Vector.<Number>(numCells, fixed);
			
			u    = new Vector.<Number>(numCells, fixed);
			uOld = new Vector.<Number>(numCells, fixed);
			v    = new Vector.<Number>(numCells, fixed);
			vOld = new Vector.<Number>(numCells, fixed);
			
			curl_abs = new Vector.<Number>(numCells, fixed);
			curl_orig = new Vector.<Number>(numCells, fixed);
			
			var i:int = numCells;
			while ( --i > -1 ) {
				u[i] = uOld[i] = v[i] = vOld[i] = 0.0;
				r[i] = rOld[i] = g[i] = gOld[i] = b[i] = bOld[i] = 0;
				curl_abs[i] = curl_orig[i] = 0;
			}
		}	
		
		
		/**
		 * this must be called once every frame to move the solver one step forward 
		*/
		public function update():void 
		{
			addSourceUV();
			
			if( _doVorticityConfinement )
			{
				calcVorticityConfinement(uOld, vOld);
				addSourceUV();
			}
			
			swapUV();
			
			diffuseUV(_visc);
			
			project(u, v, uOld, vOld);
			
			swapUV();
			
			advect(1, u, uOld, uOld, vOld);
			advect(2, v, vOld, uOld, vOld);
			
			project(u, v, uOld, vOld);
			
			if(_isRGB) {
				addSourceRGB();
				swapRGB();
				
				if( _colorDiffusion != 0 && _dt != 0 )
                {
					diffuseRGB(_colorDiffusion);
					swapRGB();
                }
				
				advectRGB(u, v);
				
				fadeRGB();
			} else {
				addSource(r, rOld);
				swapR();
				
				if( _colorDiffusion != 0 && _dt != 0 )
                {
					diffuse(0, r, rOld, _colorDiffusion);
					swapRGB();
                }
				
				advect(0, r, rOld, u, v);	
				fadeR();
			}
		}
		
		protected function calcVorticityConfinement(_x:Vector.<Number>, _y:Vector.<Number>):void
		{
			var dw_dx:Number, dw_dy:Number;
			var i:int, j:int;
			var length:Number;
			var index:int;
			var vv:Number;
			
			// Calculate magnitude of (u,v) for each cell. (|w|)
			for (j = _NY; j > 0; --j)
			{
				index = FLUID_IX(_NX, j);
				for (i = _NX; i > 0; --i)
				{
					dw_dy = u[int(index + _NX2)] - u[int(index - _NX2)];
					dw_dx = v[int(index + 1)] - v[int(index - 1)];
					
					vv = (dw_dy - dw_dx) * .5;
					
					curl_orig[ index ] = vv;
					curl_abs[ index ] = vv < 0 ? -vv : vv;
					
					--index;
				}
			}
			
			for (j = _NY-1; j > 1; --j)
			{
				index = FLUID_IX(_NX-1, j);
				for (i = _NX-1; i > 1; --i)
				{
					dw_dx = curl_abs[int(index + 1)] - curl_abs[int(index - 1)];
					dw_dy = curl_abs[int(index + _NX2)] - curl_abs[int(index - _NX2)];
					
					length = Math.sqrt(dw_dx * dw_dx + dw_dy * dw_dy) + 0.000001;
					
					length = 2 / length;
					dw_dx *= length;
					dw_dy *= length;
					
					vv = curl_orig[ index ];
					
					_x[ index ] = dw_dy * -vv;
					_y[ index ] = dw_dx * vv;
					
					--index;
				}
			}
		}
		
		protected function fadeR():void 
		{
			const holdAmount:Number = 1 - _fadeSpeed;
			
			_avgDensity = 0;
			_avgSpeed = 0;
			
			var totalDeviations:Number = 0;
			var currentDeviation:Number;
			var tmp_r:Number;
			
			var i:int = numCells;
			while ( --i > -1 ) {
				// clear old values
				uOld[i] = vOld[i] = 0; 
				rOld[i] = 0;
				
				// calc avg speed
				_avgSpeed += u[i] * u[i] + v[i] * v[i];
				
				// calc avg density
				tmp_r = Math.min(1.0, r[i]);
				_avgDensity += tmp_r;	// add it up
				
				// calc deviation (for uniformity)
				currentDeviation = tmp_r - _avgDensity;
				totalDeviations += currentDeviation * currentDeviation;
				
				// fade out old
				r[i] = tmp_r * holdAmount;
			}
			_avgDensity *= _invNumCells;
			
			_uniformity = 1.0 / (1 + totalDeviations * _invNumCells);		// 0: very wide distribution, 1: very uniform
		}
		
		protected function fadeRGB():void 
		{
			const holdAmount:Number = 1 - _fadeSpeed;
			
			_avgDensity = 0;
			_avgSpeed = 0;
			
			var totalDeviations:Number = 0;
			var currentDeviation:Number;
			var density:Number;
			
			var tmp_r:Number, tmp_g:Number, tmp_b:Number;
			
			var i:int = numCells;
			while ( --i > -1 ) {
				// clear old values
				uOld[i] = vOld[i] = 0; 
				rOld[i] = 0;
				gOld[i] = bOld[i] = 0;
				
				// calc avg speed
				_avgSpeed += u[i] * u[i] + v[i] * v[i];
				
				// calc avg density
				tmp_r = Math.min(1.0, r[i]);
				tmp_g = Math.min(1.0, g[i]);
				tmp_b = Math.min(1.0, b[i]);
				
				density = Math.max(tmp_r, Math.max(tmp_g, tmp_b));
				_avgDensity += density;	// add it up
				
				// calc deviation (for uniformity)
				currentDeviation = density - _avgDensity;
				totalDeviations += currentDeviation * currentDeviation;
				
				// fade out old
				r[i] = tmp_r * holdAmount;
				g[i] = tmp_g * holdAmount;
				b[i] = tmp_b * holdAmount;
				
			}
			_avgDensity *= _invNumCells;
			_avgSpeed *= _invNumCells;
			
			_uniformity = 1.0 / (1 + totalDeviations * _invNumCells);		// 0: very wide distribution, 1: very uniform
		}
		
		protected function addSourceUV():void 
		{
			var i:int = numCells;
			while ( --i > -1 ) {
				u[i] += _dt * uOld[i];
				v[i] += _dt * vOld[i];
			}
		}
		
		protected function addSourceRGB():void 
		{
			var i:int = numCells;
			while ( --i > -1 ) {
				r[i] += _dt * rOld[i];
				g[i] += _dt * gOld[i];
				b[i] += _dt * bOld[i];		
			}
		}
		
		protected function addSource(x:Vector.<Number>, x0:Vector.<Number>):void 
		{
			var i:int = numCells;
			while ( --i > -1 ) {
				x[i] += _dt * x0[i];
			}
		}
		
		protected function advect(b:int, _d:Vector.<Number>, d0:Vector.<Number>, du:Vector.<Number>, dv:Vector.<Number>):void 
		{
			var i:int, j:int, i0:int, j0:int, i1:int, j1:int, index:int;
			var x:Number, y:Number, s0:Number, t0:Number, s1:Number, t1:Number, dt0x:Number, dt0y:Number;
			
			dt0x = _dt * _NX;
			dt0y = _dt * _NY;
			
			for (j = _NY; j > 0; --j) {
				for (i = _NX; i > 0; --i) {
					
					index = FLUID_IX(i, j);
					
					x = i - dt0x * du[index];
					y = j - dt0y * dv[index];
					
					if (x > _NX + 0.5) x = _NX + 0.5;
					if (x < 0.5) x = 0.5;
					
					i0 = int(x);
					i1 = i0 + 1;
					
					if (y > _NY + 0.5) y = _NY + 0.5;
					if (y < 0.5) y = 0.5;
					
					j0 = int(y);
					j1 = j0 + 1;
					
					s1 = x - i0;
					s0 = 1 - s1;
					t1 = y - j0;
					t0 = 1 - t1;
					
					_d[index] = s0 * (t0 * d0[FLUID_IX(i0, j0)] + t1 * d0[FLUID_IX(i0, j1)]) + s1 * (t0 * d0[FLUID_IX(i1, j0)] + t1 * d0[FLUID_IX(i1, j1)]);
					
				}
			}
			setBoundary(b, _d);
		}
		
		protected function advectRGB(du:Vector.<Number>, dv:Vector.<Number>):void 
		{
			var i:int, j:int, i0:int, j0:int;
			var x:Number, y:Number, s0:Number, t0:Number, s1:Number, t1:Number, dt0x:Number, dt0y:Number;
			var index:int;
			
			dt0x = _dt * _NX;
			dt0y = _dt * _NY;
			
			for (j = _NY; j > 0; --j) 
			{
				for (i = _NX; i > 0; --i)
				{
					index = FLUID_IX(i, j);
					x = i - dt0x * du[index];
					y = j - dt0y * dv[index];
					
					if (x > _NX + 0.5) x = _NX + 0.5;
					if (x < 0.5)     x = 0.5;
					
					i0 = int(x);
					
					if (y > _NY + 0.5) y = _NY + 0.5;
					if (y < 0.5)     y = 0.5;
					
					j0 = int(y);
					
					s1 = x - i0;
					s0 = 1 - s1;
					t1 = y - j0;
					t0 = 1 - t1;
					
					
					i0 = FLUID_IX(i0, j0);
                    j0 = i0 + _NX2;
                    r[index] = s0 * ( t0 * rOld[i0] + t1 * rOld[j0] ) + s1 * ( t0 * rOld[int(i0+1)] + t1 * rOld[int(j0+1)] );
                    g[index] = s0 * ( t0 * gOld[i0] + t1 * gOld[j0] ) + s1 * ( t0 * gOld[int(i0+1)] + t1 * gOld[int(j0+1)] );                  
                    b[index] = s0 * ( t0 * bOld[i0] + t1 * bOld[j0] ) + s1 * ( t0 * bOld[int(i0+1)] + t1 * bOld[int(j0+1)] );				
				}
			}
			setBoundaryRGB();
		}
		
		protected function diffuse(b:int, c:Vector.<Number>, c0:Vector.<Number>, _diff:Number):void 
		{
			const a:Number = _dt * _diff * _NX * _NY;
			linearSolver(b, c, c0, a, 1.0 + 4 * a);
		}
		
		protected function diffuseRGB(_diff:Number):void 
		{
			const a:Number = _dt * _diff * _NX * _NY;
			linearSolverRGB(a, 1.0 + 4 * a);
		}
		
		protected function diffuseUV(_diff:Number):void 
		{
			const a:Number = _dt * _diff * _NX * _NY;
			linearSolverUV(a, 1.0 + 4 * a);
		}
		
		protected function project(x:Vector.<Number>, y:Vector.<Number>, p:Vector.<Number>, div:Vector.<Number>):void 
		{
			var i:int, j:int;
			var index:int;
			
			const h:Number = -0.5 / _NX;
			
			for (j = _NY; j > 0; --j) 
	        {
				index = FLUID_IX(_NX, j);
				for (i = _NX; i > 0; --i)
				{
					div[index] = h * ( x[int(index+1)] - x[int(index-1)] + y[int(index+_NX2)] - y[int(index-_NX2)] );
					p[index] = 0;
					--index;
				}
	        }
			
			setBoundary(0, div);
			setBoundary(0, p);
			
			linearSolver(0, p, div, 1, 4);
			
			const fx:Number = 0.5 * _NX;
			const fy:Number = 0.5 * _NY;
			for (j = _NY; j > 0; --j) 
			{
				index = FLUID_IX(_NX, j);
				for (i = _NX; i > 0; --i)
				{
					x[index] -= fx * (p[int(index+1)] - p[int(index-1)]);
					y[index] -= fy * (p[int(index+_NX2)] - p[int(index-_NX2)]);
					--index;
				}
			}
			
			setBoundary(1, x);
			setBoundary(2, y);
		}
		
		protected function linearSolver(b:int, x:Vector.<Number>, x0:Vector.<Number>, a:Number, c:Number):void 
		{
			var k:int, i:int, j:int;
			
			var index:int;
			
			if( a == 1 && c == 4 )
			{
				for (k = 0; k < _solverIterations; ++k) 
				{
					for (j = _NY; j > 0 ; --j) 
					{
						index = FLUID_IX(_NX, j);
						for (i = _NX; i > 0 ; --i)
						{
							x[index] = ( x[int(index-1)] + x[int(index+1)] + x[int(index - _NX2)] + x[int(index + _NX2)] + x0[index] ) * .25;
							--index;                                
						}
					}
					setBoundary( b, x );
				}
			}
			else
			{
				c = 1 / c;
				for (k = 0; k < _solverIterations; ++k) 
				{
					for (j = _NY; j > 0 ; --j) 
					{
						index = FLUID_IX(_NX, j);
						for (i = _NX; i > 0 ; --i)
						{
							x[index] = ( ( x[int(index-1)] + x[int(index+1)] + x[int(index - _NX2)] + x[int(index + _NX2)] ) * a + x0[index] ) * c;
							--index;
						}
					}
					setBoundary( b, x );
				}
			}
		}
		
		protected function linearSolverRGB(a:Number, c:Number):void 
		{
			var k:int, i:int, j:int;	
			var index3:int, index4:int, index:int;
			
			c = 1 / c;
			
			for ( k = 0; k < _solverIterations; ++k )
			{           
			    for (j = _NY; j > 0; --j)
			    {
			            index = FLUID_IX(_NX, j );
						index3 = index - _NX2;
						index4 = index + _NX2;
						for (i = _NX; i > 0; --i)
						{       
							r[index] = ( ( r[int(index-1)] + r[int(index+1)]  +  r[index3] + r[index4] ) * a  +  rOld[index] ) * c;
							g[index] = ( ( g[int(index-1)] + g[int(index+1)]  +  g[index3] + g[index4] ) * a  +  gOld[index] ) * c;
							b[index] = ( ( b[int(index-1)] + b[int(index+1)]  +  b[index3] + b[index4] ) * a  +  bOld[index] ) * c;                                
							
							--index;
							--index3;
							--index4;
						}
				}
				setBoundaryRGB();
			}
		}
		
		protected function linearSolverUV(a:Number, c:Number):void 
		{
			var index:int;
			var k:int, i:int, j:int;
			c = 1 / c;
			for (k = 0; k < _solverIterations; ++k) {
				for (j = _NY; j > 0; --j) {
					index = FLUID_IX(_NX, j);
					for (i = _NX; i > 0; --i) {
						u[index] = ( ( u[int(index-1)] + u[int(index+1)] + u[int(index - _NX2)] + u[int(index + _NX2)] ) * a  +  uOld[index] ) * c;
						v[index] = ( ( v[int(index-1)] + v[int(index+1)] + v[int(index - _NX2)] + v[int(index + _NX2)] ) * a  +  vOld[index] ) * c;
						--index;
					}
				}
				setBoundary( 1, u );
                setBoundary( 2, v );
			}
		}
		
		protected function setBoundary(bound:int, x:Vector.<Number>):void 
		{
			var dst1:int, dst2:int, src1:int, src2:int;
			var i:int;
			const step:int = FLUID_IX(0, 1) - FLUID_IX(0, 0);

			dst1 = FLUID_IX(0, 1);
			src1 = FLUID_IX(1, 1);
			dst2 = FLUID_IX(_NX+1, 1 );
			src2 = FLUID_IX(_NX, 1);
			
			if( wrap_x ) {
				src1 ^= src2;
				src2 ^= src1;
				src1 ^= src2;
			}
			if( bound == 1 && !wrap_x ) {
				for (i = _NY; i > 0; --i )
				{
					x[dst1] = -x[src1];     dst1 += step;   src1 += step;   
					x[dst2] = -x[src2];     dst2 += step;   src2 += step;   
				}
			} else {
				for (i = _NY; i > 0; --i )
				{
					x[dst1] = x[src1];      dst1 += step;   src1 += step;   
					x[dst2] = x[src2];      dst2 += step;   src2 += step;   
				}
			}
			
			dst1 = FLUID_IX(1, 0);
			src1 = FLUID_IX(1, 1);
			dst2 = FLUID_IX(1, _NY+1);
			src2 = FLUID_IX(1, _NY);
			
			if( wrap_y ) {
				src1 ^= src2;
				src2 ^= src1;
				src1 ^= src2;
			}
			if( bound == 2 && !wrap_y ) {
				for (i = _NX; i > 0; --i )
				{
				        x[dst1++] = -x[src1++]; 
				        x[dst2++] = -x[src2++]; 
				}
			} else {
				for (i = _NX; i > 0; --i )
				{
				        x[dst1++] = x[src1++];
				        x[dst2++] = x[src2++];  
				}
			}
			
			x[FLUID_IX(  0,   0)] = 0.5 * (x[FLUID_IX(1, 0  )] + x[FLUID_IX(  0, 1)]);
			x[FLUID_IX(  0, _NY+1)] = 0.5 * (x[FLUID_IX(1, _NY+1)] + x[FLUID_IX(  0, _NY)]);
			x[FLUID_IX(_NX+1,   0)] = 0.5 * (x[FLUID_IX(_NX, 0  )] + x[FLUID_IX(_NX+1, 1)]);
			x[FLUID_IX(_NX+1, _NY+1)] = 0.5 * (x[FLUID_IX(_NX, _NY+1)] + x[FLUID_IX(_NX+1, _NY)]);
			 
		}
		
		protected function setBoundaryRGB():void 
		{
			if( !wrap_x && !wrap_y ) return;
			
			var dst1:int, dst2:int, src1:int, src2:int;
			var i:int;
			const step:int = FLUID_IX(0, 1) - FLUID_IX(0, 0);
			
			if ( wrap_x ) {
				dst1 = FLUID_IX(0, 1);
				src1 = FLUID_IX(1, 1);
				dst2 = FLUID_IX(_NX+1, 1 );
				src2 = FLUID_IX(_NX, 1);
				
				src1 ^= src2;
				src2 ^= src1;
				src1 ^= src2;
				
				for (i = _NY; i > 0; --i )
				{
					r[dst1] = r[src1]; g[dst1] = g[src1]; b[dst1] = b[src1]; dst1 += step;   src1 += step;   
					r[dst2] = r[src2]; g[dst2] = g[src2]; b[dst2] = b[src2]; dst2 += step;   src2 += step;   
				}
			}
			
			if ( wrap_y ) {
				dst1 = FLUID_IX(1, 0);
				src1 = FLUID_IX(1, 1);
				dst2 = FLUID_IX(1, _NY+1);
				src2 = FLUID_IX(1, _NY);
				
				src1 ^= src2;
				src2 ^= src1;
				src1 ^= src2;
				
				for (i = _NX; i > 0; --i )
				{
					r[dst1] = r[src1]; g[dst1] = g[src1]; b[dst1] = b[src1];  ++dst1; ++src1;   
					r[dst2] = r[src2]; g[dst2] = g[src2]; b[dst2] = b[src2];  ++dst2; ++src2;   
				}
			}
		}	
		
		protected function swapUV():void
		{
			_tmp = u; 
			u = uOld; 
			uOld = _tmp;
			
			_tmp = v; 
			v = vOld; 
			vOld = _tmp; 
		}
		
		protected function swapR():void
		{ 
			_tmp = r;
			r = rOld;
			rOld = _tmp;
		}
		
		protected function swapRGB():void
		{ 
			_tmp = r;
			r = rOld;
			rOld = _tmp;
			
			_tmp = g;
			g = gOld;
			gOld = _tmp;
			
			_tmp = b;
			b = bOld;
			bOld = _tmp;
		}
		
		protected function FLUID_IX(i:int, j:int):int
		{ 	if (i + _NX2 * j < u.length)
			return int(i + _NX2 * j);
			else
			return u.length - 1;
		}
		
		public function shiftLeft():void
        {                
			var j:int = _NX2 - 1, k:int, ind:int;
			for (var i:int = 0; i < _NY2; i++)
			{
				k = i * _NX2 + j;
				ind = k - j;
				
				r.splice.apply( r, [k, 0].concat(r.splice(ind, 1)) );
				g.splice.apply( g, [k, 0].concat(g.splice(ind, 1)) );
				b.splice.apply( b, [k, 0].concat(b.splice(ind, 1)) );
				
				u.splice.apply( u, [k, 0].concat(u.splice(ind, 1)) );
				v.splice.apply( v, [k, 0].concat(v.splice(ind, 1)) );
				
				rOld.splice.apply( rOld, [k, 0].concat(rOld.splice(ind, 1)) );
				gOld.splice.apply( gOld, [k, 0].concat(gOld.splice(ind, 1)) );
				bOld.splice.apply( bOld, [k, 0].concat(bOld.splice(ind, 1)) );
				
				uOld.splice.apply( uOld, [k, 0].concat(uOld.splice(ind, 1)) );
				vOld.splice.apply( vOld, [k, 0].concat(vOld.splice(ind, 1)) );
			}
        }
        
        public function shiftRight():void
        {                
			var j:int = _NX2 - 1, k:int, ind:int;
			for (var i:int = 0; i < _NY2; i++)
			{
				k = i * _NX2 + j;
				ind = k - j;
				
				r.splice.apply( r, [ind, 0].concat(r.splice(k, 1)) );
				g.splice.apply( g, [ind, 0].concat(g.splice(k, 1)) );
				b.splice.apply( b, [ind, 0].concat(b.splice(k, 1)) );
				
				u.splice.apply( u, [ind, 0].concat(u.splice(k, 1)) );
				v.splice.apply( v, [ind, 0].concat(v.splice(k, 1)) );
				
				rOld.splice.apply( rOld, [ind, 0].concat(rOld.splice(k, 1)) );
				gOld.splice.apply( gOld, [ind, 0].concat(gOld.splice(k, 1)) );
				bOld.splice.apply( bOld, [ind, 0].concat(bOld.splice(k, 1)) );
				
				uOld.splice.apply( uOld, [ind, 0].concat(uOld.splice(k, 1)) );
				vOld.splice.apply( vOld, [ind, 0].concat(vOld.splice(k, 1)) );
			}
        }
        
        public function shiftUp():void
        {
			r = r.concat(r.slice(0, _NX2));
			r.splice(0, _NX2);
			
			g = g.concat(g.slice(0, _NX2));
			g.splice(0, _NX2);
			
			b = b.concat(b.slice(0, _NX2));
			b.splice(0, _NX2);
			
			u = u.concat(u.slice(0, _NX2));
			u.splice(0, _NX2);
			
			v = v.concat(v.slice(0, _NX2));
			v.splice(0, _NX2);
			
			rOld = rOld.concat(rOld.slice(0, _NX2));
			rOld.splice(0, _NX2);
			
			gOld = gOld.concat(gOld.slice(0, _NX2));
			gOld.splice(0, _NX2);
			
			bOld = bOld.concat(bOld.slice(0, _NX2));
			bOld.splice(0, _NX2);
			
			uOld = uOld.concat(uOld.slice(0, _NX2));
			uOld.splice(0, _NX2);
			
			vOld = vOld.concat(vOld.slice(0, _NX2));
			vOld.splice(0, _NX2);
        }
        
        public function shiftDown():void
        {
			const offset:int = (_NY2 - 1) * _NX2;
			const offset2:int = offset + _NX2;
			 
			r = r.slice(offset, offset2).concat(r);
			r.splice(numCells, _NX2);
			
			g = g.slice(offset, offset2).concat(g);
			g.splice(numCells, _NX2);
			
			b = b.slice(offset, offset2).concat(b);
			b.splice(numCells, _NX2);
			
			u = u.slice(offset, offset2).concat(u);
			u.splice(numCells, _NX2);
			
			v = v.slice(offset, offset2).concat(v);
			v.splice(numCells, _NX2);
			
			rOld = rOld.slice(offset, offset2).concat(rOld);
			rOld.splice(numCells, _NX2);
			
			gOld = gOld.slice(offset, offset2).concat(gOld);
			gOld.splice(numCells, _NX2);
			
			bOld = bOld.slice(offset, offset2).concat(bOld);
			bOld.splice(numCells, _NX2);
			
			uOld = uOld.slice(offset, offset2).concat(uOld);
			uOld.splice(numCells, _NX2);
			
			vOld = vOld.slice(offset, offset2).concat(vOld);
			vOld.splice(numCells, _NX2);
        }
		
		public function set deltaT(dt:Number):void 
		{
			_dt = dt;	
		}
		
		/**
		 * @param fadeSpeed (0...1)
		 */
		public function set fadeSpeed(fadeSpeed:Number):void 
		{
			_fadeSpeed = fadeSpeed;	
		}
	
		
		/**
		 * set number of iterations for solver (higher is slower but more accurate) 
		 */	
		public function set solverIterations(solverIterations:int):void 
		{
			_solverIterations = solverIterations;	
		}
		
		/**
		 * set whether solver should work with monochrome dye (default) or RGB
		 */		
		public function set rgb(isRGB:Boolean):void 
		{
			_isRGB = isRGB;
		}
			
		public function set viscosity(newVisc:Number):void 
		{
			_visc = newVisc;
		}
		
		public function get viscosity():Number 
		{
			return _visc;
		}
		
		public function set colorDiffusion(cd:Number):void
		{
			_colorDiffusion = cd;
		}
		
		public function set vorticityConfinement(val:Boolean):void
		{
			_doVorticityConfinement = val;
		}
		
		public function randomizeColor():void 
		{
			var index:int;
			var i:int, j:int;
			for(i = 0; i < width; i++) {
				for(j = 0; j < height; j++) {
					index = FLUID_IX(i, j);
					r[index] = rOld[index] = Math.random();
					if(_isRGB) {
						g[index] = gOld[index] = Math.random();
						b[index] = bOld[index] = Math.random();
					}
				} 
			}
		}
				
		public function getIndexForCellPosition(i:int, j:int):int 
		{
			if(i < 1) i=1; else if(i > _NX) i = _NX;
			if(j < 1) j=1; else if(j > _NY) j = _NY;
			return FLUID_IX(i, j);
		}
		
		public function getIndexForXYPosition(X:int, Y:int, screenWidth:int, screenHeight:int):int 
		{
			var i:int = X;
			var j:int = Y;
			i = Math.floor(i / (screenWidth / _NX2));
			j = Math.floor(j / (screenHeight / _NY2));
			if(i < 1) i=0; else if(i > _NX2) i = _NX2;
			if (j < 1) j=0; else if(j > _NY2) j = _NY2;
			
			return FLUID_IX(i, j);
		}
		
		public function getIndexForNormalizedPosition(x:Number, y:Number):int 
		{
			return getIndexForCellPosition(int(x * _NX2), int(y * _NY2));
		}
		
		public function setWrap(x:Boolean = false, y:Boolean = false):void
		{
			wrap_x = x;
			wrap_y = y;
		}
		
		public function get wrapX():Boolean
		{
			return wrap_x;
		}
		
		public function get wrapY():Boolean
		{
			return wrap_y;
		}
		
		public function get avgDensity():Number 
		{
			return _avgDensity;
		}
		
		public function get uniformity():Number 
		{
			return _uniformity;
		}
			
		public function get avgSpeed():Number 
		{
			return _avgSpeed;
		}
		
		
		
		
	}
}
