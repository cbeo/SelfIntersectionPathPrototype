package;

import openfl.display.Sprite;
import openfl.events.MouseEvent;
import haxe.Timer;
import haxe.ds.Option;

typedef Pt= {x:Float, y:Float};

enum Line {
  Vertical(xVal:Float);
  Horizontal(yVal:Float);
  Sloped(slop:Float,yIntercept:Float);
}


class Main extends Sprite
{
  var sampled:Array<Pt>;

  var drawing = false;
  var timestamp:Float;

  public function new()
  {
    super();

    stage.addEventListener( MouseEvent.MOUSE_DOWN, onMouseDown);
    stage.addEventListener( MouseEvent.MOUSE_UP, onMouseUp);
    stage.addEventListener( MouseEvent.MOUSE_MOVE, onMouseMove);

  }

  function lineOfSegment (a:Pt,b:Pt):Line
  {
    if (a.x == b.x)
      return Vertical(a.y);

    if (a.y == b.y)
      return Horizontal(a.x);

    var slope = (b.y - a.y) / (b.x - a.x);
    var yIntercept = a.y - slope * a.x;
    return Sloped(slope,yIntercept);
  }

  function isCounterClockwiseOrder(a:Pt,b:Pt,c:Pt) {
    return (b.x - a.x) * (c.y - a.y) > (b.y - a.y) * (c.x - a.x);
  }

  function linesIntersect (a:Pt,b:Pt,c:Pt,d:Pt) : Bool {
    return (isCounterClockwiseOrder( a, c, d) != isCounterClockwiseOrder(b, c, d)) &&
      (isCounterClockwiseOrder( a ,b, c) != isCounterClockwiseOrder(a, b, d));
  }

  function linesIntersectAt (a:Pt,b:Pt,c:Pt,d:Pt) : Option<Pt>
  {
    var line1 = lineOfSegment(a,b);
    var line2 = lineOfSegment(c,d);

    trace([line1, line2]);
    switch ([line1, line2])
      {
      case [Sloped(m1,b1), Sloped(m2,b2)]:
        var x = (b2 - b1) / (m1 - m2);
        var y = m1 * x + b1;
        return Some({x:x,y:y});

      case [Sloped(m,b), Vertical(x)] | [Vertical(x), Sloped(m,b)]:
        var y = m * x + b;
        return Some({x:x,y:y});

      case [Sloped(m,b), Horizontal(y)] | [Horizontal(y), Sloped(m,b)]:
        var x = (y - b) / m;
        return Some({x:x,y:y});

      case [Horizontal(y),Vertical(x)] | [Vertical(y), Horizontal(x)]:
        return Some({x:x,y:y});

      default:
        return None;
      }
  }
  
  function findSelfIntersectionIndex (p:Pt ) : Option<Int>
  {
    if ( sampled.length > 0) {
      var last = sampled.length - 1;

      for (i in 1 ... last) 
        if (linesIntersect( sampled[i-1], sampled[i], sampled[last], p)) 
          return Some(i);
    }
    return None;      
  }

  function findSelfIntersectionPt (p:Pt ) : Option<Pt>
  {
    if ( sampled.length > 0) {
      var last = sampled.length - 1;

      for (i in 1 ... last) 
        if (linesIntersect( sampled[i-1], sampled[i], sampled[last], p)) 
          return linesIntersectAt( sampled[i-1], sampled[i], sampled[last], p );
    }
    return None;      
  }
  
  function selfIntersectionCheck( p:Pt ) : Bool
  {
    return switch (findSelfIntersectionIndex( p ))
      {
      case  Some(_): true;
      case None: false;
      };
  }
  
  function onMouseDown (e) {
    drawing = true;
    timestamp = Timer.stamp();
    sampled = [ {x:e.localX, y:e.localY} ];
    graphics.clear();
    graphics.lineStyle(3,0);
    graphics.moveTo( e.localX, e.localY );
  }

  function onMouseUp (e) {
    drawing = false;
  }

  function drawSampled()
  {
    graphics.clear();
    graphics.lineStyle(3, 0);
    graphics.moveTo( sampled[0].x,  sampled[0].y );

    for (i in 1...sampled.length)
      graphics.lineTo( sampled[i].x, sampled[i].y );

    graphics.lineTo(sampled[0].x, sampled[0].y);
  }

  function onMouseMove (e) {
    var stamp = Timer.stamp();
    var pt = {x:e.localX, y:e.localY};

    if (drawing && (stamp - timestamp > 0.01)) {
      switch (findSelfIntersectionIndex( pt ))
        {
        case Some(i):
          var firstAndLastOption = findSelfIntersectionPt( pt );
          drawing = false;
          sampled = sampled.slice(i);

          trace(firstAndLastOption);
          var firstAndLast = switch(firstAndLastOption)
            {case Some(pt):pt; default:sampled[0];};

          trace(firstAndLast);
          
          sampled[0] = firstAndLast;

          drawSampled();
          return; // exiting early.. a little ugly.
          
        case None: {}
        }      

      timestamp = stamp;
      sampled.push( pt );
      graphics.lineTo( e.localX, e.localY );
    }
    
  }


}
