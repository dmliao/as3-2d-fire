package com.amorphous.flame
{
	import com.amorphous.flame.fields.Fields;
	import com.amorphous.flame.fields.WindPoint;
	import com.amorphous.flame.particles.display.FireCreator;
	import com.amorphous.flame.particles.display.ParticleDisplay;
	import com.amorphous.flame.particles.objects.Particle;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.BlendMode;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.filters.BlurFilter;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuBuiltInItems;
	import flash.ui.ContextMenuItem;
	import flash.utils.getTimer;
	
	import ru.inspirit.utils.ColorUtils;
	import ru.inspirit.utils.FluidSolver;
	
	/**
	 * Class that contains all of the components of the flame, and can be created on-stage to produce a flame
	 * @author Diana Liao
	 */
	public class Fire extends Sprite
	{
		/**
		 * Container for the fluid objects, including oxygen, fuel, and heat fields
		 */
		private var fireFields:Fields;
		
		/**
		 * Container for the display functions for the particles
		 */
		private var fireCreator:FireCreator;
		
		/**
		 * Width of the whole simulation
		 */
		private var sw:uint;
		
		/**
		 * Height of the whole simulation
		 */
		private var sh:uint;
		
		/**
		 * Image variables for the FUEL field
		 */
		private var fuel:BitmapData;
		private var fuelBuffer:Vector.<uint>;
		
		/**
		 * Image variables for the OXYGEN field
		 */
		private var oxygen:BitmapData;
		private var oxyBuffer:Vector.<uint>;
		
		/**
		 * Image variables for the HEAT field
		 */
		private var heat:BitmapData;
		private var heatBuffer:Vector.<uint>;
		
		/**
		 * Container for forces acting on the fire
		 */
		private var forceContainer:Array = new Array();
	
		/**
		 * Maximum number of particles onscreen at a time
		 */
		private var maxPart:Number = 100;
		
		private const origin:Point = new Point();
		private const identity:Matrix = new Matrix();
		private const blur:BlurFilter = new BlurFilter( 1, 1, 0 );
		private const fade2black:ColorTransform = new ColorTransform( 0.9, 0.9, 0.9 );
		private const fade2alpha:ColorTransform = new ColorTransform( 1, 1, 1, .7);
		
		private var drawScale:Number = 1;
		
		private var isw:Number;
		private var ish:Number;
		
		private var aspectRatio:Number;
		private var aspectRatio2:Number;
		
		private var screen:BitmapData;
		
		private var fade:BitmapData;
		
		private var drawMatrix:Matrix;
		private var drawColor:ColorTransform;
		
		private var mx:uint = 0;
		private var my:uint = 0;
		
		private var display:Bitmap;
		private var prevMouse:Point = new Point();
		private var fuelImage:Bitmap;
		private var oxyImage:Bitmap;
		private var heatImage:Bitmap;
		private var heatMask:Bitmap;
		
		/**
		 * Bitmapdata used to draw the color spectrum of the fire
		 */
		private var spectrum:BitmapData;
		
		/**
		 * Whether or not smoke is drawn
		 */
		private var smoke:Boolean = true;
		
		/**
		 * Size of each individual particle
		 */
		private var partSize:uint = 4;
		
		/**
		 * Type of particle drawn
		 */
		private var partType:uint = 0;
		
		/**
		 * Color of the smoke
		 */
		private var sColor:uint = 0x777777;
		/**
		 * Constructor. Used to create a new Fire object
		 * @param	X					X position of the rectangle that serves as the bounds of the simulation
		 * @param	Y					Y position of the rectangle that serves as the bounds of the simulation
		 * @param	gridWidth			Width of the rectangle that serves as the bounds of the simulation
		 * @param	gridHeight			Height of the rectangle that serves as the bounds of the simulation
		 * @param	numCellsX			Number of columns for the simulation grid
		 * @param	numCellsY			Number of rows for the simulation grid
		 * @param   particleType		Type of shape used in drawing the particle (0 = rectangle, 1 = ellipse, 2 = line, 3 = image)
		 * @param   particleImage       Bitmap used to draw every individual particle [optional]
		 */
		public function Fire(X:uint, Y:uint, gridWidth:uint,gridHeight:uint,numCellsX:uint,numCellsY:uint,particleType:uint = 0,particleImage:Bitmap = null)
		{
			fireFields = new Fields(numCellsX,numCellsY);
			
			x = X;
			y = Y;
			
			sw = gridWidth;
			sh = gridHeight;
			
			if (particleType == 0 || particleType == 1 || particleType == 2 || particleType == 3)
			{
				partType = particleType;
			}
			
			
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		// INITIALIZING THE STAGE AND IMAGES
		/////////////////////////////////////
		private function init(e:Event = null):void
		{
			
			fireFields.cellwidth = sw / (fireFields.width + 2);
			fireFields.cellheight = sh / (fireFields.height + 2);
			removeEventListener(Event.ADDED_TO_STAGE, init);

			var dw:Number = sw / fireFields.width;
			var dh:Number = sh / fireFields.height;
			var s:Number = dw > dh ? dw : dh;
			
			fuel = new BitmapData(fireFields.fuel.width, fireFields.fuel.height, false, 0);
			fuelBuffer = new Vector.<uint>(fuel.width * fuel.height, true);
			
			oxygen = new BitmapData(fireFields.oxygen.width, fireFields.oxygen.height, false, 0);
			oxyBuffer = new Vector.<uint>(oxygen.width * oxygen.height, true);
			
			heat = new BitmapData(fireFields.heat.width, fireFields.heat.height, true, 0xFF000000);
			heatBuffer = new Vector.<uint>(heat.width * heat.height, true);
			
			//drawing the fuel
			fuelImage = new Bitmap( fuel, 'never', true );
			fuelImage.width = sw;
			fuelImage.height = sh;
			
			//drawing the oxygen
			oxyImage = new Bitmap( oxygen, 'never', true );
			oxyImage.width = sw;
			oxyImage.height = sh;
			
			//drawing the oxygen
			heatImage = new Bitmap( heat, 'never', true );
			heatImage.width = sw;
			heatImage.height = sh;
			heatImage.visible = false;
			
			var fadeImage:Bitmap = new Bitmap(fade, 'never', true);
			
			display = new Bitmap( screen, 'never', true );
			
			fadeImage.scaleX = fadeImage.scaleY = 1 / drawScale;
			
			display.blendMode = fadeImage.blendMode = BlendMode.ADD;
			
			isw = 1 / sw;
			ish = 1 / sh;
			aspectRatio = sw * ish;
			aspectRatio2 = aspectRatio * aspectRatio;
			
			screen = new BitmapData(sw, sh, true, 0);
			
			fade = new BitmapData(sw * drawScale, sh * drawScale, false, 0x0);
			
			drawMatrix = new Matrix(drawScale, 0, 0, drawScale, 0, 0);
			drawColor = new ColorTransform(0.1, 0.1, 0.1);
			
			fireCreator = new FireCreator(this, sw, sh, true);
			
			//Set the particle type (from constructor)
			fireCreator.display.partType = partType;
			
		
		//	addChild(oxyImage);
			addChild(heatImage);
			addChild(fireCreator);
			fireCreator.startFlow();
			
			addEventListener(Event.ENTER_FRAME, render);
		}
		
		
		//UPDATING AND DRAWING
		/////////////////////////
		private function render(e:Event):void 
		{
		//	drawFuelBitmap();
			drawOxyBitmap();
			updateForces();
		//	if (fireCreator.display.numOnStage < maxParticles)
			{
				for (var num:Number = 0; num < 1; num += 1)
				{
					fireCreator.addParticles(fireFields, partSize, maxParticles);
					
				}
			}
			fireFields.update();
			if (smoke==true)
			{
				heatImage.visible = true;
				drawHeatBitmap();
			}
			else
			{
				heatImage.visible = false;
			}
			//update particles
			fireCreator.display.update(fireFields);
		}
		
		private function drawFuelBitmap():void
		{
			const d:int = 0xFF * 1;
			const fw:int = fireFields.fuel.width;
			const tw:int = fw - 1;
			const th:int = fireFields.fuel.height - 1;
			
			var i:int, j:int, fi:int;
			var index:int = 0;
			
			for(j = 1; j < th; ++j) {
				for(i = 1; i < tw; ++i) {
					index = fireFields.fuel.getIndexForCellPosition(i, j);
					fuelBuffer[ index ] = ((fireFields.fuel.r[index] * d));
					//draws fuel as WHITE blocks
				}
			}
			fuel.lock();
			fuel.setVector(fuel.rect, fuelBuffer );
			fuel.applyFilter( fuel, fuel.rect, origin, blur );
			fuel.unlock(fuel.rect);
		}
		
		private function drawOxyBitmap():void
		{
			const d:int = 0xFF * 1;
			const fw:int = fireFields.oxygen.width;
			const tw:int = fw - 1;
			const th:int = fireFields.oxygen.height - 1;
			
			var i:int, j:int, fi:int;
			var index:int = 0;
			
			for(j = 1; j < th; ++j) {
				for(i = 1; i < tw; ++i) {
					index = fireFields.oxygen.getIndexForCellPosition(i, j);
					oxyBuffer[ index ] = ((fireFields.oxygen.r[index] * d));
					
				}
			}
			
			oxygen.lock();
			oxygen.setVector(oxygen.rect, oxyBuffer );
			oxygen.applyFilter( oxygen, oxygen.rect, origin, blur );
			oxygen.unlock(oxygen.rect);
		}
		
		private function drawHeatBitmap():void
		{
			const d:int = 0xFF * 1;
			const fw:int = fireFields.heat.width;
			const tw:int = fw - 1;
			const th:int = fireFields.heat.height - 1;
			
			var i:int, j:int, fi:int;
			var index:int = 0;
			
			for(j = 1; j < th; ++j) {
				for(i = 1; i < tw; ++i) {
					fi = int(i + fw * j);
					index = fireFields.heat.getIndexForCellPosition(i,j);
					//TWEAK FIRST PARAMETER FOR ALPHA
					
		//			{
		//				heatBuffer[ index ] = ((fireFields.heat.r[index] * d) << 24) | ((fireFields.heat.r[index] * d / 2) << 16) | ((fireFields.heat.r[index] * d / 2) << 8) | (fireFields.heat.r[index] * d / 2);
		//			}
		//			else
		//			{
		//				heatBuffer[ index ] = ((fireFields.heat.r[index] * d) << 24) | ((fireFields.heat.r[index] * d * 2) << 16) | ((fireFields.heat.r[index] * d * 2) << 8) | (fireFields.heat.r[index] * d *2);
		//				if (heatBuffer[ index ] < 16777216)
		//				{
		//					heatBuffer[index] = 16777216;
		//				}
		//			}
					var red:uint = sColor >> 16;
					var blugreen:uint = sColor - (red<<16);
					var green:uint = blugreen >> 8;
					var blue:uint = blugreen-(green<<8);
					heatBuffer[ index ] = ((fireFields.heat.r[index] * d) << 24) | (red) << 16| (green) << 8 | (blue);
				}
			}
			heat.lock();
			heat.setVector( heat.rect, heatBuffer );
			heat.applyFilter( heat, heat.rect, origin, blur );
			heat.unlock(heat.rect);
			
		}
		
		private function updateForces():void
		{
			var index:Number = 0;
			while (index < forceContainer.length)
			{
				var currentForce:WindPoint = forceContainer[index] as WindPoint;
				var currentI:int = fireFields.heat.getIndexForXYPosition(currentForce.x,currentForce.y,sw,sh);
				fireFields.heat.v[currentI] += currentForce.forceY;
				fireFields.heat.u[currentI] += currentForce.forceX;
				index += 1;
			}
		}
		
		// PUBLIC FUNCTIONS
		////////////////////////
		
		/**
		 * Width of the whole simulation (Set in constructor)
		 */
		public function get simWidth():uint
		{
			return sw;
		}
		
		/**
		 * Height of the whole simulation (Set in constructor)
		 */
		public function get simHeight():uint
		{
			return sh;
		}
		
		/**
		 * Maximum number of particles on the simulation at one frame
		 */
		public function get maxParticles():int
		{
			return maxPart;
		}
		
		/**
		 * Maximum number of particles on the simulation at one frame
		 */
		public function set maxParticles(limit:int):void
		{
			maxPart = limit;
		}
		/**
		 * The array with the list of forces
		 */
		public function get forces():Array
		{
			return forceContainer;
		}
		
		/**
		 * The bitmap that the flame gets its color from. The color data is taken from the first row of pixels, 
		 * with the lowest heat value at the leftmost pixel, and the highest heat value at the rightmost pixel
		 */
		public function get colorSpectrum():BitmapData
		{
			return spectrum;
		}
		
		/**
		 * The bitmap that the flame gets its color from. The color data is taken from the first row of pixels, 
		 * with the lowest heat value at the leftmost pixel, and the highest heat value at the rightmost pixel
		 */
		public function set colorSpectrum(color:BitmapData):void
		{
			spectrum = color;
			fireFields.initFireColors(spectrum);
		}
		
		/**
		 * Exothermicness: How much heat is released at every step of the simulation
		 */
		public function get exothermicness():Number
		{
			return fireFields.exothermic;
		}
		
		/**
		 * Exothermicness: How much heat is released at every step of the simulation
		 */
		public function set exothermicness(exo:Number):void
		{
			fireFields.exothermic = exo;
		}
		
		/**
		 * DrawSmoke: Boolean-Whether or not the smoke (heat field bitmapdata) will be drawn
		 */
		public function get drawSmoke():Boolean
		{
			return smoke;
		}
		
		/**
		 * DrawSmoke: Boolean-Whether or not the smoke (heat field bitmapdata) will be drawn
		 */
		public function set drawSmoke(draw:Boolean):void
		{
			smoke = draw;
		}
		
		/**
		 * SmokeColor: The color of the smoke. Set as a hexadecimal value.
		 */
		public function get smokeColor():uint
		{
			return sColor;
		}
		
		/**
		 * SmokeColor: The color of the smoke. Set as a hexadecimal value.
		 */
		public function set smokeColor(s:uint):void
		{
			sColor = s;
		}
		
		/**
		 * ParticleSize: Pixel size of the particles
		 */
		public function get particleSize():uint
		{
			return partSize;
		}
		
		/**
		 * ParticleSize: Pixel size of the particles
		 */
		public function set particleSize(size:uint):void
		{
			partSize = size;
		}
		
		/**
		 * ParticleType: The shape used to draw the fire particles
		 */
		public function get particleType():uint
		{
			return fireCreator.display.partType;
		}
		
		/**
		 * ParticleType: The shape used to draw the fire particles
		 */
		public function set particleType(type:uint):void
		{
			fireCreator.display.partType = type;
		}
		
		/**
		 * ParticleImage: Bitmapdata used as the sprite for each individual particle (incomplete)
		 */
		public function get particleImage():Bitmap
		{
			return fireCreator.display.particleImage;
		}
		
		/**
		 * ParticleImage: Bitmapdata used as the sprite for each individual particle (incomplete)
		 */
		public function set particleImage(img:Bitmap):void
		{
			fireCreator.display.particleImage = img;
			fireCreator.display.setParticleImage();
		}
		
		/**
		 * CellAtXYPos: Returns the index of the cell at the Point(x,y)
		 * @param	X					X position of the cell (in pixels)
		 * @param	Y					Y position of the cell (in pixels)
		 */
		public function cellAtXYPos(x:uint, y:uint):int
		{
			return fireFields.heat.getIndexForXYPosition(x, y, sw, sh);
		}
		
		/**
		 * burnFuelPoint: Fills a cell at the specified point with fuel and heat 
		 * @param	x					X position of the cell (relative to the position of the simulation box)
		 * @param	Y					Y position of the cell (relative to the position of the simulation box)
		 */
		public function burnFuelPoint(x:int,y:int):void
		{
			fireFields.fuel.r[fireFields.heat.getIndexForXYPosition(x,y,sw,sh)] = 1;
			fireFields.heat.r[fireFields.heat.getIndexForXYPosition(x,y,sw,sh)] = fireFields.oxygen.r[fireFields.heat.getIndexForXYPosition(x,y,sw,sh)];
		}
		
		/**
		 * addFuelPoint: Fills a cell at the specified point with fuel 
		 * @param	x					X position of the cell (relative to the position of the simulation box)
		 * @param	Y					Y position of the cell (relative to the position of the simulation box)
		 */
		public function addFuelPoint(x:int,y:int):void
		{
			fireFields.fuel.r[fireFields.heat.getIndexForXYPosition(x,y,sw,sh)] = 1;
		}
		
		
		/**
		 * burnFuelCircle: Creates a circle of fuel and heat at the given point (relative to x and y of the simulation box)
		 * @param	x					X position of the center of the circle. (Nearest cell)
		 * @param	Y					Y position of the center of the circle. (Nearest cell)
		 * @param	radius				Radius of the circle (in number of cells)
		 */
		public function burnFuelCircle(x:int, y:int, radius:Number):void
		{
			var i:int = x;
			var j:int = y;
			i = Math.floor(i / (sw / fireFields.width));
			j = Math.floor(j / (sh / fireFields.height));
			if(i < 1) i=1; else if(i > fireFields.width) i = fireFields.width;
			if (j < 1) j=1; else if(j > fireFields.height) j = fireFields.height;
			
			var X:int = i;
			var Y:int = j;
			
			for(var yy:int=-radius; yy<=radius; yy+=1)
			{
				var tempY:int = Y + yy;
				
				for(var xx:int=-radius; xx<=radius; xx+=1)
				{
					var tempX:int = X + xx;
					
					if(xx*xx+yy*yy <= radius*radius)
					{
						fireFields.fuel.r[fireFields.fuel.getIndexForCellPosition(X+xx,Y+yy)] = 1;
						fireFields.heat.r[fireFields.fuel.getIndexForCellPosition(X+xx,Y+yy)] = fireFields.oxygen.r[fireFields.fuel.getIndexForCellPosition(X+xx,Y+yy)];
					}
				}
			}
		}
		
		/**
		 * addFuelCircle: Creates a circle of fuel at the given point (relative to x and y of the simulation box)
		 * @param	x					X position of the center of the circle. (Nearest cell)
		 * @param	Y					Y position of the center of the circle. (Nearest cell)
		 * @param	radius				Radius of the circle (in number of cells)
		 */
		public function addFuelCircle(x:int, y:int, radius:Number):void
		{
			var i:int = x;
			var j:int = y;
			i = Math.floor(i / (sw / fireFields.width));
			j = Math.floor(j / (sh / fireFields.height));
			if(i < 1) i=1; else if(i > fireFields.width) i = fireFields.width;
			if (j < 1) j=1; else if(j > fireFields.height) j = fireFields.height;
			
			var X:int = i;
			var Y:int = j;
			
			for(var yy:int=-radius; yy<=radius; yy+=1)
			{
				var tempY:int = Y + yy;
				
				for(var xx:int=-radius; xx<=radius; xx+=1)
				{
					var tempX:int = X + xx;
					
					if(xx*xx+yy*yy <= radius*radius)
					{
						fireFields.fuel.r[fireFields.fuel.getIndexForCellPosition(X+xx,Y+yy)] = 1;
					}
				}
			}
		}
		
		/**
		 * blanketFuel: Covers the whole simulation box with fuel
		 */
		public function blanketFuel():void
		{
			var i:int;
			var j:int;
			var index:int;
			for(j = 0; j < fireFields.height; j += 1) {
				for(i = 0; i < fireFields.width; i += 1) {
					index = fireFields.heat.getIndexForCellPosition(i, j);
					fireFields.fuel.r[index] = 1;
					
				}
			}
		}
		
		/**
		 * addWallPoint: Fills a cell at the specified point with a wall 
		 * @param	x					X position of the cell (relative to the position of the simulation box)
		 * @param	Y					Y position of the cell (relative to the position of the simulation box)
		 */
		public function addWallPoint(x:int,y:int):void
		{
			fireFields.walls.r[fireFields.heat.getIndexForXYPosition(x,y,sw,sh)] = 1;
		}
		/**
		 * addWallCircle: Creates a circle of fuel at the given point (relative to x and y of the simulation box)
		 * @param	x					X position of the center of the circle. (Nearest cell)
		 * @param	Y					Y position of the center of the circle. (Nearest cell)
		 * @param	radius				Radius of the circle (in number of cells)
		 */
		public function addWallCircle(x:int, y:int, radius:Number):void
		{
			var i:int = x;
			var j:int = y;
			i = Math.floor(i / (sw / fireFields.width));
			j = Math.floor(j / (sh / fireFields.height));
			if(i < 1) i=1; else if(i > fireFields.width) i = fireFields.width;
			if (j < 1) j=1; else if(j > fireFields.height) j = fireFields.height;
			
			var X:int = i;
			var Y:int = j;
			
			for(var yy:int=-radius; yy<=radius; yy+=1)
			{
				var tempY:int = Y + yy;
				
				for(var xx:int=-radius; xx<=radius; xx+=1)
				{
					var tempX:int = X + xx;
					
					if(xx*xx+yy*yy <= radius*radius)
					{
						fireFields.walls.r[fireFields.fuel.getIndexForCellPosition(X+xx,Y+yy)] = 1;
					}
				}
			}
		}
		
		/**
		 * Add force: adds a force at a specific point with a specific direction and magnitude
		 */
		public function addForce(xx:Number,yy:Number,force:Number,direction:Number):void
		{
			forceContainer.push(new WindPoint(xx,yy,direction,force));
		}
	}
}