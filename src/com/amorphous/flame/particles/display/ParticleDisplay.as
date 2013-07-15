
package com.amorphous.flame.particles.display
{
	import com.amorphous.flame.Fire;
	import com.amorphous.flame.fields.Fields;
	import com.amorphous.flame.particles.dataStructures.LinkedList;
	import com.amorphous.flame.particles.objects.Particle;
	
	import flash.display.*;
	import flash.display.Sprite;
	import flash.geom.*;
	
	/**
	 * Class used to wrap display of particles. Not to be used on its own. Modified from the particle example at http://www.flashandmath.com/
	 * @link http://www.flashandmath.com/
	 */
	public class ParticleDisplay extends Sprite {
		
		public var gravity:Number;
		
		public var partType:int = 0;
		
		//The linked list onStageList is a list of all the raindrops currently
		//being animated.		
		private var onStageList:LinkedList;
		//The recycleBin stores raindrops that are no longer part of the animation, but 
		//which can be used again when new drops are needed.
		private var recycleBin:LinkedList;
		
		public var numOnStage:Number;
		public var numInRecycleBin:Number;
		public var displayWidth:Number;
		public var displayHeight:Number;
		
		//a vector defining wind velocity:
		public var wind:Point;
		
		public var defaultInitialVelocity:Point;
		public var defaultDropThickness:Number;
		public var windOnSplash:Number;
		public var noSplashes:Boolean;
		
		//the defaultDropColor is only used when drops are not randomly colored by
		//grayscale, gradient, or fully random color.
		public var defaultDropColor:uint;
		
		public var randomizeColor:Boolean;
		public var colorMethod:String;
		public var minGray:Number;
		public var maxGray:Number;
		public var _gradientColor1:uint;
		public var _gradientColor2:uint;
		public var dropLength:String;
		public var minSplashDrops:Number;
		public var maxSplashDrops:Number;
		public var defaultDropAlpha:Number;
		public var splashAlpha:Number;
		public var splashThickness:Number;
		public var splashMinVelX:Number;
		public var splashMaxVelX:Number;
		public var splashMinVelY:Number;
		public var splashMaxVelY:Number;
		
		//If drops go outside of the xRange of the viewable window, they can be
		//removed from the animation or kept in play.  If the wind is rapidly changing,
		//there is a possibility of the raindrops reemerging from the side, so
		//you may wish to keep the following variable set to false.
		public var removeDropsOutsideXRange:Boolean;
		
		//These variance parameters allow for controlled random variation in
		//raindrop velocities.
		public var initialVelocityVarianceX:Number;
		public var initialVelocityVarianceY:Number;
		public var initialVelocityVariancePercent:Number;
		
		public var globalBreakawayTime:Number;
		public var breakawayTimeVariance:Number;
		
		private var displayMask:Sprite;
		private var left:Number;
		private var right:Number;
		private var r1:Number;
		private var g1:Number;
		private var b1:Number;
		private var r2:Number;
		private var g2:Number;
		private var b2:Number;
		private var param:Number;
		private var r:Number;
		private var g:Number;
		private var b:Number;
		private var numSplashDrops:int;
		private var outsideTest:Boolean;		
		private var variance:Number;
		private var dropX:Number;
		
		private var fireTemp:Fire;
		
		public var particleImage:Bitmap;
		
		public function ParticleDisplay(firetemplate:Fire, w:int = 400, h:int=300, useMask:Boolean = true) {			
			displayWidth = w;
			displayHeight = h;
			onStageList = new LinkedList();
			recycleBin = new LinkedList();
			wind = new Point(0,0);
			defaultInitialVelocity = new Point(0,0);
			initialVelocityVarianceX = 0;
			initialVelocityVarianceY = 0;
			initialVelocityVariancePercent = 0;
			windOnSplash = 0.20;
			
			noSplashes = false;
			
			fireTemp = firetemplate;
			
			numOnStage = 0;
			numInRecycleBin = 0;
			
			if (useMask) {
				displayMask = new Sprite();
				displayMask.graphics.beginFill(0xFFFF00);
				displayMask.graphics.drawRect(0,0,w,h);
				displayMask.graphics.endFill();
				this.addChild(displayMask);
				this.mask = displayMask;
			}
			
			
			defaultDropColor = 0xFFFFFF;
			defaultDropThickness = 1;
			defaultDropAlpha = 1;
			gravity = 1;
			randomizeColor = true;
			colorMethod = "gray";
			minGray = 0;
			maxGray = 1;
			_gradientColor1 = 0x0000FF;
			_gradientColor2 = 0x00FFFF;
			dropLength = "short";
			
			splashAlpha = 0.6;
			splashThickness = 1;
			minSplashDrops = 4;
			maxSplashDrops = 8;
			splashMinVelX = -2.5;
			splashMaxVelX = 2.5;
			splashMinVelY = 1.5;
			splashMaxVelY = 4;
			
			removeDropsOutsideXRange = true;
			
			globalBreakawayTime = 0;
			breakawayTimeVariance = 0;
			
			this.blendMode = "add";
		}
		
		public function get gradientColor1():uint {
			return _gradientColor1;
		}
		
		public function get gradientColor2():uint {
			return _gradientColor2;
		}
		
		public function set gradientColor1(input:uint):void {
			_gradientColor1 = uint(input);
			r1 = (_gradientColor1 >>16) & 0xFF;
			g1 = (_gradientColor1 >>8) & 0xFF;
			b1 = _gradientColor1 & 0xFF;
		}
		
		public function set gradientColor2(input:uint):void {
			_gradientColor2 = uint(input);
			r2 = (_gradientColor2 >>16) & 0xFF;
			g2 = (_gradientColor2 >>8) & 0xFF;
			b2 = _gradientColor2 & 0xFF;
		}
		
		//arguments are x, y, velx, vely, color, thickness, splashing
		public function addDrop(x0:Number, y0:Number, ...args):Particle {
			numOnStage++;
			var drop:Particle; 
			var dropColor:uint;
			var dropThickness:Number;
			
			//set thickness
			if (args.length > 3) {
				dropThickness = args[3];
			}
			else {
				dropThickness = defaultDropThickness;
			}
			
			//check recycle bin for available drop:
			if (recycleBin.first != null) {
				numInRecycleBin--;
				drop = recycleBin.first;
				//remove from bin
				if (drop.next != null) {
					recycleBin.first = drop.next;
					drop.next.prev = null;
				}
				else {
					recycleBin.first = null;
				}
				drop.resetPosition(x0,y0);
				drop.visible = true;
			}
				//if the recycle bin is empty, create a new drop:
			else {
				drop = new Particle(x0,y0,particleImage);
				//add to display
				this.addChild(drop);
			}
			
			drop.thickness = dropThickness;
			//drop.color = dropColor;
			
			//add to beginning of onStageList
			if (onStageList.first == null) {
				onStageList.first = drop;
				drop.prev = null; //may be unnecessary
				drop.next = null;
			}
			else {
				drop.next = onStageList.first;
				onStageList.first.prev = drop;  //may be unnecessary
				onStageList.first = drop;
				drop.prev = null; //may be unnecessary
			}
			
			//set initial velocity
			if (args.length < 2) {
				variance = (1+Math.random()*initialVelocityVariancePercent);
				drop.vel.x = defaultInitialVelocity.x*variance+Math.random()*initialVelocityVarianceX;
				drop.vel.y = defaultInitialVelocity.y*variance+Math.random()*initialVelocityVarianceY;
			}
			else {
				drop.vel.x = args[0];
				drop.vel.y = args[1];
			}
			
			//set alpha
			if (args.length > 4) {
				drop.alpha = args[4];
			}
			else {
				drop.alpha = defaultDropAlpha;
			}
			
			//set splashing/non-splashing type
			if (args.length > 5) {
				drop.splashing = args[5];
			}
			else {
				//turn off splashing if global noSplashes is set to true.
				//otherwise, make the drop a splashing type.
				drop.splashing = false;
			}
			
			drop.atTerminalVelocity = false;
			
			drop.lifespan = 0;
			drop.breakawayTime = globalBreakawayTime*(1+breakawayTimeVariance*Math.random());
			
			return drop;
		}
		
		public function update(fire:Fields):void {
			var drop:Particle = onStageList.first;
			var nextDrop:Particle;
			while (drop != null) {
				//before lists are altered, record next drop
				nextDrop = drop.next;
				//move all drops. For each drop in onStageList:
				drop.lifespan++;
				
				//only update if drop's lifespan is beyond breakaway time.
				if (drop.lifespan > drop.breakawayTime) {
					
					
					//COLOR FUNCTION
					//////////////////
					drop.particleType = partType;
					
					//record lastLastPos
					drop.lastLastPos.x = drop.lastPos.x;
					drop.lastLastPos.y = drop.lastPos.y;
					
					//record lastPos
					drop.lastPos.x = drop.p1.x;
					drop.lastPos.y = drop.p1.y;
					
					//update position p1
					//As an aesthetic choice, we apply less wind to the splashes than
					//to the falling raindrops.
					
						drop.p1.x += drop.vel.x;
						drop.p1.y += drop.vel.y;
					
					//update p0				
					if (dropLength == "long") {
						//use for longer drops:
						drop.p0.x = drop.lastLastPos.x;
						drop.p0.y = drop.lastLastPos.y;
					}
					else if (dropLength == "short") {
						drop.p0.x = drop.lastPos.x;
						drop.p0.y = drop.lastPos.y;
					}
					else {
						//can add other kinds of dropLength types, for example, constant length.
					}
				}	
				
				//KILL THE DROP IF THE HEAT IS ZERO
				convectParticle(drop, fire);
				mapColor(fire,drop);
				killParticle(drop, fire, 2);
				
				//call redrawing function
				drop.redraw();
				
				drop = nextDrop;
			}
		}
		
		public function recycleDrop(drop:Particle):void {
			numOnStage--;
			numInRecycleBin++;
		//	trace(numOnStage);
			
			drop.visible = false;
			drop.alpha = 1;
			drop.lastPos.x = 25;
			drop.lastPos.y = 25;
			drop.pos.x = 0;
			drop.pos.y = 0;
			
			//remove from onStageList
			if (onStageList.first == drop) {
				if (drop.next != null) {
					drop.next.prev = null;
					onStageList.first = drop.next;
				}
				else {
					onStageList.first = null;
				}
			}
			else {
				if (drop.next == null) {
					drop.prev.next = null;
				}
				else{
					drop.prev.next = drop.next;
					drop.next.prev = drop.prev;
				}
			}
			
			//add to recycle bin
			if (recycleBin.first == null) {
				recycleBin.first = drop;
				drop.prev = null; //may be unnecessary
				drop.next = null;
			}
			else {
				drop.next = recycleBin.first;
				recycleBin.first.prev = drop;  //may be unnecessary
				recycleBin.first = drop;
				drop.prev = null; //may be unnecessary
			}
		}
		
		public function convectParticle(particle:Particle, fire:Fields):void
		{
			particle.vel.x = fire.heat.u[fire.heat.getIndexForXYPosition(particle.lastPos.x, particle.lastPos.y, fireTemp.simWidth, fireTemp.simHeight)]*fireTemp.simWidth/1.5;
			particle.vel.y = fire.heat.v[fire.heat.getIndexForXYPosition(particle.lastPos.x, particle.lastPos.y, fireTemp.simWidth, fireTemp.simHeight)]*fireTemp.simHeight/fire.exothermic;
			
		}
		
		public function killParticle(particle:Particle, fire:Fields, alphaFactor:Number = 1):void
		{
			particle.alpha = fire.heat.r[fire.heat.getIndexForXYPosition(particle.lastPos.x, particle.lastPos.y, fireTemp.simWidth, fireTemp.simHeight)]*alphaFactor;
			if (particle.lastPos.x < 0)
			{
			//	trace("kx");
				recycleDrop(particle);
				
			}
			if (particle.lastPos.y < 0)
			{
			//	trace("ky");
				recycleDrop(particle);
				
			}
			if (fire.heat.r[fire.heat.getIndexForXYPosition(particle.lastPos.x, particle.lastPos.y, fireTemp.simWidth, fireTemp.simHeight)] <= 0.2 && particle.visible == true)
			{
				recycleDrop(particle);
				
			}
			if (particle.alpha <= 0.05)
			{
				recycleDrop(particle);
			//	trace("ka");
			}
			
		}
		
		private function createSplash(x0:Number, c:uint):void {
			numSplashDrops = Math.ceil(minSplashDrops + Math.random()*(maxSplashDrops - minSplashDrops));
			for (var i:int = 0; i<=numSplashDrops-1; i++) {
				//arguments are x, y, velx, vely, color, thickness
				var randomSplashSize:Number = 0.75+0.75*Math.random();
				var velX:Number = randomSplashSize*(splashMinVelX+Math.random()*(splashMaxVelX-splashMinVelX));
				var velY:Number = -randomSplashSize*(splashMinVelY+Math.random()*(splashMaxVelY-splashMinVelY));
				var thisDrop:Particle = addDrop(x0, displayHeight, velX, velY, c, splashThickness, splashAlpha, false);
				thisDrop.breakawayTime = 0;
			}
		}
		
		public function mapColor(fire:Fields,particle:Particle):void
		{
			particle.color = fire.getColors(fire.heat.r[fire.heat.getIndexForXYPosition(particle.lastPos.x, particle.lastPos.y, fireTemp.simWidth, fireTemp.simHeight)]);
		}
		
		public function setParticleImage():void
		{
			var drop:Particle = onStageList.first;
			while (drop != null) {
				drop.setImage(particleImage);
				drop = drop.next;
			}
		}
		
	}
}