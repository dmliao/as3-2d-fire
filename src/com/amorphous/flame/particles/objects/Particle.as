package com.amorphous.flame.particles.objects
{
	import com.amorphous.flame.fields.Fields;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.filters.BlurFilter;
	import flash.geom.*;
	
	/**
	 * Individual particles class. Not to be used on its own. Modified from the particle example at http://www.flashandmath.com/
	 * @link http://www.flashandmath.com/
	 */
	public class Particle extends Sprite
	{
		public var lifespan:int;
		public var breakawayTime:int = 100;
		
		public var fade:Number;
		
		public var thickness:Number;
		
		public var pos:Point;		
		public var vel:Point;
		public var accel:Point;
		
		public var color:uint;
		
		//drawing points
		public var p0:Point;
		public var p1:Point;
		
		public var lastPos:Point;
		public var lastLastPos:Point;
		
		public var radiusWhenStill:Number;
		
		//The following attributes are for the purposes of creating a
		//linked list of LineRaindrop instances.
		public var next:Particle;
		public var prev:Particle;
		
		public var splashing:Boolean;
		public var atTerminalVelocity:Boolean;
		
		public var colorTransform:ColorTransform = new ColorTransform();
		
		/*
		Image-based particles still are not implemented in any meaningful way, but
		all of the variables and particle functions have been set. What remains to be done
		is to set a bitmap image and actually test the implementation of bitmap particles
		*/
		public var image:Bitmap = null;
		
		/**
		 * Particle Type
		 * 0 = rectangular 'line-type'
		 * 1 = ellipse particles
		 * 2 = line "impressionist" particles
		 * 3 = image-based particles (INCOMPLETE)
		 */
		public var particleType:uint = 2;
		
		public function Particle(x0:Number=0,y0:Number=0,img:Bitmap = null)
		{
			super();
			lastPos = new Point(x0,y0);
			lastLastPos = new Point(x0,y0);
			pos = new Point(x0,y0);
			p0 = new Point(x0,y0);
			p1 = new Point(x0,y0);
			accel = new Point();
			vel = new Point();
			fade = 1;
			thickness = 1;
			color = 0xFF0000;
			splashing = true;
			atTerminalVelocity = false;
			radiusWhenStill = 3;
			image = img;
			if (particleType == 3 && image != null)
			{
				addChild(image);
			}
		}
		
		public function setImage(img:Bitmap):void
		{
			if (this.contains(image))
			{
			//	removeChild(image);
			}
			image = img;
			if (particleType == 3 && image != null)
			{
				addChild(image);
			}
		}
		
		public function resetPosition(x0:Number=0,y0:Number=0):void {
			lastPos = new Point(x0,y0);
			lastLastPos = new Point(x0,y0);
			pos = new Point(x0,y0);
			p0 = new Point(x0,y0);
			p1 = new Point(x0,y0);
		}
		
		//Draws the particle as an ellipse followed by a fading line.
		public function redraw():void {
			switch (particleType)
			{
				case 0:
				{
					//RECTANGLE PARTICLES
					////////////////////////
					
					this.graphics.clear();
					this.graphics.lineStyle(thickness,color, alpha,false,"normal","none");
					
					this.graphics.moveTo(p0.x,p0.y);
					this.graphics.lineTo(p0.x+thickness,p0.y+thickness);
					this.graphics.beginFill(color, alpha);
					this.graphics.endFill();
					
				}break;
				
				case 1:
				{
					//ELLIPSE PARTICLES
					////////////////////////
					
					this.graphics.clear();
					this.graphics.beginFill(color, alpha);
					this.graphics.drawEllipse(p0.x-(thickness/2),p0.y-(thickness/2),2*(thickness/2),2*(thickness/2));
					this.graphics.endFill();
				}break;
				
				case 2:
				{
					//LINE PARTICLES
					//////////////////
						
					this.graphics.clear();
					if (lifespan < breakawayTime) {
					this.graphics.beginFill(color);
					this.graphics.drawEllipse(p1.x-radiusWhenStill,p1.y-radiusWhenStill,2*radiusWhenStill,2*radiusWhenStill)
					this.graphics.endFill();
					}
					else {			
					this.graphics.lineStyle(thickness,color,1,false,"normal","none");
					this.graphics.moveTo(p0.x,p0.y);
					this.graphics.lineTo(p1.x,p1.y);
					}
					//	this.blendMode = "add";
					
				}break;
				
				case 3:
				{
					//IMAGE PARTICLES
					////////////////////
					if (image != null)
					{
						if (!this.contains(image) && image != null)
						{
							addChild(image);
						}
						image.alpha = alpha;
				//		image.scaleX = thickness / 100;
				//		image.scaleY = thickness / 100;
						image.x = x - (image.width/2)*(image.scaleX);
						image.y = y - (image.height/2)*(image.scaleY);
						colorTransform.color = color;
				//		image.transform.colorTransform = colorTransform;
					
					}
					else
					{
						//ELLIPSE PARTICLES (FALLBACK)
						////////////////////////////////
						
						this.graphics.clear();
						this.graphics.beginFill(color, alpha);
						this.graphics.drawEllipse(p0.x-(thickness/2),p0.y-(thickness/2),2*(thickness/2),2*(thickness/2));
						this.graphics.endFill();
					}
				}break;
			}
		
		}
	}
}