package com.amorphous.flame.particles.display
{
	import com.amorphous.flame.Fire;
	import com.amorphous.flame.fields.Fields;
	import com.amorphous.flame.particles.objects.Particle;
	
	import flash.display.*;
	import flash.display.Sprite;
	import flash.events.*;
	import flash.filters.*;
	import flash.geom.*;

	/**
	 * Class used to display the fire particles. Not to be used on its own. Modified from the particle example at http://www.flashandmath.com/
	 * @link http://www.flashandmath.com/
	 */
	public class FireCreator extends Sprite {
		public var blur:BlurFilter;
		public var colorFade:ColorTransform;
		public var dropsToAddEachFrame:int;
		public var bgColor:uint;
		public var angle:Number;
		public var display:ParticleDisplay;
		public var leftMargin:Number;
		public var topMargin:Number;
		public var waterTopWidth:Number;
		public var displayHeight:Number;
		public var displayWidth:Number;
		
		public var minAngle:Number;
		public var maxAngle:Number;
		public var minMagnitude:Number;
		public var maxMagnitude:Number;
		
		public var flowOn:Boolean;
		
		private var _dropAlpha:Number;
		private var _splashDropAlpha:Number;
		private var _targetColor:uint;
		private var _fadeAmount:Number;
		private var magnitude:Number;
		private var origin:Point;
		private var bitmapData:BitmapData;
		private var bitmap:Bitmap;		

		
		public function FireCreator(_fireTemp:Fire, _displayWidth:Number=250, _displayHeight:Number=400, transparency:Boolean = false) {
			
			super();
			
			origin = new Point(0,0);
			dropsToAddEachFrame = 8;
			
			displayHeight = _displayHeight;
			displayWidth = _displayWidth;
			topMargin = 20;
			leftMargin = 2;
			waterTopWidth = 72;
			
			minAngle = Math.PI/12;
			maxAngle = Math.PI/3;
			minMagnitude = 0.7;
			maxMagnitude = 1.3;
			
			_splashDropAlpha = 0.3;
			_dropAlpha = 0.45;
			
			display = new ParticleDisplay(_fireTemp,displayWidth,displayHeight,false);
			
			blur = new BlurFilter(4,4,3);
			
			//WILL EDIT FOR COLOR EFFECTS
			_targetColor = 0xFFFFFF;
			_fadeAmount = -30; //arbitrary number to fade out the particle trails
			
			var colorTargetR:Number = (_targetColor >> 16);
			var colorTargetG:Number = (_targetColor >> 8) & 0xFF;
			var colorTargetB:Number = _targetColor & 0xFF;
			colorFade = new ColorTransform();
			colorFade.redMultiplier = Math.pow(colorTargetR/255,0.03);
			colorFade.greenMultiplier = Math.pow(colorTargetG/255,0.03);
			colorFade.blueMultiplier = Math.pow(colorTargetB/255,0.03);
			colorFade.alphaMultiplier = 1;
			colorFade.alphaOffset = _fadeAmount;
			
			/*
			display.defaultDropColor = 0xffffff;
			display.randomizeColor = false;
			*/
			
			/*
			display.colorMethod = "random";
			*/
			
			
			display.colorMethod = "gradient";
			display.gradientColor1 = 0xFFaaaa;
			display.gradientColor2 = 0xffffff;
			
			
			
		//	display.colorMethod = "gray";
	//		display.minGray = 0.9;
	//		display.maxGray = 1;
			
			
			display.defaultDropThickness = 1;
			display.splashThickness = 1;
			display.gravity = 0;
			
			display.initialVelocityVariancePercent = 0.5;
			display.initialVelocityVarianceX=0;
			display.initialVelocityVarianceY=0;
			display.dropLength = "short";
			
			display.defaultDropAlpha = _dropAlpha;
			display.splashAlpha = _splashDropAlpha;
			display.splashMaxVelX = 0.8;
			display.splashMinVelX = -0.8;
			display.splashMinVelY = 0.4;
			display.splashMaxVelY = 1.8;
			
			display.minSplashDrops = 2;
			display.maxSplashDrops = 3;
			
			display.removeDropsOutsideXRange = false;
			
			if (transparency) {
				bitmapData = new BitmapData(display.displayWidth, display.displayHeight, true, 0x00000000);
			}
			else {
				bitmapData = new BitmapData(display.displayWidth, display.displayHeight, false, 0x000000);
			}
			
			bitmap = new Bitmap(bitmapData);
			bitmap.x = 0;
			bitmap.y = 0;
			this.addChild(bitmap);
			
			display.wind = new Point(0,0);
			
			flowOn = false;
			
			this.addEventListener(Event.REMOVED_FROM_STAGE, removedFromStageListener);
			this.addEventListener(Event.ADDED_TO_STAGE, addedToStageListener);
		}
		
		private function addedToStageListener(evt:Event):void {
			//When waterfall is added to stage, we start the animation.
			this.stage.addEventListener(Event.ENTER_FRAME, onEnter);
		}
		
		private function removedFromStageListener(evt:Event):void {
			//If the waterfall is removed from the stage, we should stop animating it.
			this.stage.removeEventListener(Event.ENTER_FRAME, onEnter);
		}
		
		public function set dropAlpha(a:Number):void {
			_dropAlpha = a;
			display.defaultDropAlpha = _dropAlpha;
		}
		
		public function get dropAlpha():Number {
			return _dropAlpha;
		}
		
		public function set splashDropAlpha(n:Number):void {
			_splashDropAlpha = n;
			display.splashAlpha = _splashDropAlpha;
		}
		
		public function get splashDropAlpha():Number {
			return _splashDropAlpha;
		}
		
		public function set targetColor(c:uint):void {
			_targetColor = c;
			var colorTargetR:Number = (_targetColor >> 16);
			var colorTargetG:Number = (_targetColor >> 8) & 0xFF;
			var colorTargetB:Number = _targetColor & 0xFF;
			colorFade = new ColorTransform();
			colorFade.redMultiplier = Math.pow(colorTargetR/255,0.03);
			colorFade.greenMultiplier = Math.pow(colorTargetG/255,0.03);
			colorFade.blueMultiplier = Math.pow(colorTargetB/255,0.03);
			colorFade.alphaMultiplier = 1;
			colorFade.alphaOffset = _fadeAmount;
		}
		
		public function set fadeAmount(n:Number):void {
			_fadeAmount = n;
			colorFade.alphaOffset = _fadeAmount;
		}
		
		public function set noSplashes(b:Boolean):void {
			this.display.noSplashes = b;
		}
		
		public function get noSplashes():Boolean {
			return this.display.noSplashes;
		}
		
		public function startFlow():void {
			flowOn = true;
		}
		
		public function stopFlow():void {
			flowOn = false;
		}
		
		private function onEnter(evt:Event):void {
			if (flowOn) {
				//add water drops
				for (var i:int = 0; i <= 8; i++) {
					angle = minAngle + Math.random()*(maxAngle - minAngle);
					magnitude = minMagnitude + Math.random()*(maxMagnitude - minMagnitude);
					
				/*	var thisDrop = display.addDrop(
						300,
						topMargin,
						magnitude*Math.cos(angle),
						-magnitude*Math.sin(angle));
					
					*/
					
				}
			}
			
			bitmapData.colorTransform(bitmapData.rect, colorFade);
			bitmapData.applyFilter(bitmapData,bitmapData.rect,origin,blur);
			
			bitmapData.draw(display);
		}
		
		public function addParticles(fire:Fields, size:Number = 4, maxParticles:Number = 1000):void
		{
			if (flowOn)
			{
				var i:int;
				var j:int;
				var index:int;
				
				for (i = 1; i < fire.width; i += 1)
				{
					for (j = 1; j < fire.height; j += 1)
					{
						index = fire.fuel.getIndexForCellPosition(i, j);
						if (display.numOnStage < maxParticles)
						{
						if (fire.fuel.r[index] > 0.2 || fire.heat.r[index] > 0.3)
						{
							var thisParticle:Particle = display.addDrop(
								fire.getCellX(i, j) + fire.cellwidth*Math.random(), //X position of the particle
								fire.getCellY(i, j) + fire.cellwidth*Math.random(), //Y position of the particle
								2, //X Velocity
								3, //Y Velocity
								0xFF0000, //Color
								size); //Size
						}
						}
					}
				}
			}
		}
		
		
		
	}
}