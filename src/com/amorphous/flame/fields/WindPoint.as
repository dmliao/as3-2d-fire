package com.amorphous.flame.fields
{
	import com.amorphous.flame.Fire;
	
	import flash.geom.Point;

	public class WindPoint extends Point
	{
		public var direction:Number = 0;
		public var force:Number = 0;
		
		public var forceX:Number;
		public var forceY:Number;
		public function WindPoint(xx:Number,yy:Number, dir:Number, force:Number)
		{
			super(xx,yy);
			this.direction = dir;
			this.force = force;
			forceX = force*Math.cos(direction * Math.PI/180);
			forceY = -force*Math.sin(direction * Math.PI/180);
		}
		public function update():void
		{
			//wind operations
			forceX = force*Math.cos(direction * Math.PI/180);
			forceY = -force*Math.sin(direction * Math.PI/180);
		}
		private function radtodeg(angle:Number):Number
		{
			return angle * 180 / Math.PI;
		}
		private function degtorad(angle:Number):Number
		{
			return angle * Math.PI / 180;
		}
	}
}