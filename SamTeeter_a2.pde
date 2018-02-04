Table table;
int[] yValues;
String[] xTitles;
color barColor;
color lightBarColor;
BarGraph barGraph;
LineGraph lineGraph;
ToggleButton button;

void setup(){
  //setup canvas
  size(1000, 700);
  surface.setResizable(true);
  
  //load data
  table = loadTable("dataset.csv");
  yValues = new int[table.getRowCount()];
  xTitles = new String[table.getRowCount()];
  int i=0;
  for (TableRow row : table.rows()){
    int y = row.getInt(1);
    String t = row.getString(0);
    yValues[i] = y;
    xTitles[i] = t;
    i++;
  }
  
  //create graphs, button
  button = new ToggleButton(50, 25, 150, 75);
  barGraph = new BarGraph(xTitles, yValues, 50, 150, width-100, height-200);
  lineGraph = new LineGraph(xTitles, yValues, 50, 150, width-100, height-200);
  lineGraph.doTransition(lgTransition.hidden);
  barGraph.doTransition(bgTransition.showing);
}

void draw(){
  background(255,255,255);
  
  //scale graph to fit canvas
  int graphX, graphY, graphW, graphH;
  graphX = 50;
  graphY = 50;
  graphH = height-2*graphY;
  graphW = width-2*graphX;
  
  //update graph dimensions if necessary
  if (barGraph.graphH != graphH || barGraph.graphW != graphW){
    barGraph.updateScale(graphX, graphY, graphW, graphH);
    lineGraph.updateScale(graphX, graphY, graphW, graphH);
  }
  //draw 1 background
  barGraph.drawBackground();
  
  //draw graphs
  //remove bar graph if linegraph is in
  if (lineGraph.currTransition==lgTransition.linesIn
  && lineGraph.transProgress >= 1-lineGraph.transSpeed){
    barGraph.doTransition(bgTransition.barsToPoints);
  }
  //and vice versa 
  else if (barGraph.currTransition == bgTransition.pointsToBars
  && barGraph.transProgress >= 1-barGraph.transSpeed ){
    lineGraph.doTransition(lgTransition.linesOut);
  }
  barGraph.drawGraph();
  lineGraph.drawGraph();
  
  //show button
  button.draw();
}

void mouseClicked(){
  if (button.wasClicked()){
    if (lineGraph.currTransition == lgTransition.showing
    && barGraph.currTransition == bgTransition.hidden ){
      barGraph.doTransition(bgTransition.pointsToBars);
    } else if (lineGraph.currTransition==lgTransition.hidden){
      if (barGraph.currTransition==bgTransition.showing){
        lineGraph.doTransition(lgTransition.linesIn);
      }
    }
  }
}

class ToggleButton{
  int x, y, h, w;
  color fillColor;
  
  ToggleButton(int X,int Y,int W, int H){
    fillColor = color(0,0,139);
    update(X,Y,W,H);
  }
  
  void update(int X, int Y, int W, int H){
    x=X;
    y=Y;
    w=W;
    h=H;
  }
  
  void draw(){
    fill(fillColor);
    if (mouseInRect(x,y,w,h)){
      fill(lerpColor(fillColor, color(255,255,255), .1));
    }
    rect(x,y,w,h);
    fill(255,255,255);
    textSize(18);
    textAlign(CENTER, CENTER);
    text("Toggle", x+w/2, y+h/2);
  }
  
  boolean wasClicked(){
    return mouseInRect(x,y,w,h);
  }
}

class Graph{
  //generic class for resizeable graph with x-titles and y-values
  
  int graphZeroY;
  String[] titles;
  int[] values;
  int yScale, xW, maxY, minY;
  int graphX, graphY, graphW, graphH;
  
  Graph(String[] t, int[] v, int x, int y, int w, int h){
    
    titles = t;
    values = v;
    
    //calculate scaling factors for data
    maxY=Integer.MIN_VALUE;
    minY=Integer.MAX_VALUE;
    for (int value : values) {
      maxY = max(value, maxY);
      minY = min(value, minY);
    }
    
    updateScale(x, y, w, h);    
  }
  
  void updateScale(int x, int y, int w, int h){
    //recalculate scaling factors
    graphX = x;
    graphY = y;
    graphW = w;
    graphH = h;
    
    int yRange = max(0, maxY) - min(0, minY);
    yScale = (graphH-40)/yRange;
    graphZeroY = graphY + graphH + min(minY, 0)*yScale -20;
    xW = graphW / values.length - 5;
  }
  
  void drawBackground(){
    //draw the graph background
    fill(255,255,255);
    rect(graphX, graphY, graphW, graphH);
    
    //draw y-labels
    fill(0,0,0);
    textSize(12);
    textAlign(LEFT);
    for (int y=0; y<maxY; y+=5){
      text(str(y), graphX-20, graphZeroY-y*yScale);   
    }
    for (int y=0; y>=minY; y-=5){
      text(str(y), graphX-20, graphZeroY-y*yScale);
    }
  }
}

public enum bgTransition{
    showing, hidden, pointsToBars, barsToPoints
}
  
class BarGraph extends Graph{
  
  color barColor, lightBarColor;
  bgTransition currTransition;
  private float transProgress, transSpeed;  
  
  BarGraph(String[] t, int[] v, int x, int y, int w, int h){
    super(t, v, x, y, w, h);
    barColor = color(246, 176, 146);
    lightBarColor = lerpColor(barColor, color(255,255,255), .2);
    currTransition = bgTransition.showing;
    transProgress = 0;
    transSpeed = .02;
  }
  
  void doTransition(bgTransition trans){
    currTransition = trans;
    transProgress = 0;
  }
  
  void drawGraph(){
    switch( currTransition ){
      case showing:
        drawBars();
        break;
      case barsToPoints:
        drawBarsToPoints();
        break;
      case pointsToBars:
        drawPointsToBars();
        break;
      default:
        break;
    }
  }
  
  private void drawBars(){
    int barX = graphX;
    int barH, barY;
    for (int i=0; i<values.length; i++){
      if (values[i] >= 0){
        barH = values[i] * yScale;
        barY = graphZeroY-barH;
      } else {
        barH = -values[i] * yScale;
        barY = graphZeroY;
      }
      
      if (mouseInRect(barX, barY, xW, barH)){
        //mouseover behavior. Write in text over top
        fill(0,0,0);
        int labelX = barX+xW/2;
        int labelY;
        if( values[i] >= 0){
          labelY = graphZeroY - barH - 5;
        } else {
          labelY = graphZeroY + barH + 12;
        }
        String labelstr = '('+titles[i]+", "+str(values[i])+')';
        textAlign(CENTER);
        text(labelstr, labelX, labelY);
        //and lighten the color of the bar itself
        fill(lightBarColor);
      } else {
        fill(barColor);
      }
      
      rect(barX, barY, xW, barH);
      fill(0,0,0);
      textAlign(LEFT);
      text(titles[i], barX+xW/2, graphY+graphH+15);
      barX += xW;
    }
  }
  
  private void drawBarsToPoints(){
    int barX = graphX;
    float barH, barY, transXW;
        
    transProgress += transSpeed;
    if (transProgress >= 1){
      transProgress = 1;
      currTransition = bgTransition.hidden;
    }
    
    for (int i=0; i<values.length; i++){
      if (values[i] >=0){
        barH = lerp(values[i]*yScale, 0, transProgress);
        barY = graphZeroY - values[i] * yScale;
      } else {
        barH = lerp(-values[i]*yScale, 0, transProgress);
        barY = graphZeroY-values[i]*yScale-barH;
      }
      transXW = abs(barH)/abs(values[i]*yScale) * xW;
      
      fill(barColor);
      rect(barX, barY, transXW, barH);
      barX += xW;
      
    }
  }
  
  private void drawPointsToBars(){
    int barX = graphX;
    float barH, barY, transXW;
    
    transProgress += transSpeed;
    if (transProgress >= 1){
      transProgress = 1;
      currTransition = bgTransition.showing;
    }
    
    for (int i=0; i<values.length; i++){
      if (values[i]>=0){
        barH = lerp(0, values[i]*yScale, transProgress);
        barY = graphZeroY - values[i] * yScale;
      } else {
        barH = lerp(0, -values[i]*yScale, transProgress);
        barY = graphZeroY-values[i]*yScale-barH;
      }
      transXW = abs(barH)/abs(values[i]*yScale)*xW;
      
      fill(barColor);
      rect(barX, barY, transXW, barH);
      barX += xW;
    }
  }
}

enum lgTransition{
  linesIn, linesOut, pointsIn, pointsOut, showing, hidden
}

class LineGraph extends Graph{
  
   int pD, maxpD;
   color pointColor, lightPointColor; 
   lgTransition currTransition;
   float transProgress, transSpeed;
   
   LineGraph(String[] t, int[] v, int x, int y, int w, int h){
     super(t, v, x, y, w, h);
     pointColor = color(246, 176, 146);
     lightPointColor = lerpColor(pointColor, color(255,255,255), .2);
     pD = maxpD = 15;
     currTransition = lgTransition.showing;
     transProgress = 0;
     transSpeed = 0.02;
   }
   
   void doTransition(lgTransition trans){
     currTransition = trans;
     transProgress = 0;
   }
   
   void drawGraph(){
     
     switch(currTransition){
       case showing:
         drawPoints();
         break;
       case linesIn:
         drawLinesIn();
         break;
       case linesOut:
         drawLinesOut();
         break;
       default:
         break;
     }
   }
   
   void drawPoints(){
    int pX = graphX;
    int i=0;
    int prevX=0, prevY=0;
    stroke(pointColor);
    for (int y : values){
      int pY = graphZeroY-y*yScale;
          
      //draw lines
      strokeWeight(5);
      if(i >0){
        line(prevX, prevY, pX, pY);
      }
      strokeWeight(1);
      
      //draw points
      if (mouseInRect(pX-pD/2, pY-pD/2, pD, pD)){
        //write label over point
        fill(0,0,0);
        int labelX = pX;
        int labelY = pY - pD;
        String labelstr = '('+titles[i]+", "+str(values[i])+')';
        textAlign(CENTER);
        text(labelstr, labelX, labelY);
        fill(lightPointColor);
      } else {
        fill(pointColor);
      }
      ellipse(pX,pY,pD,pD);
      
      //x-axis labels
      fill(0,0,0);
      textSize(12);
      textAlign(LEFT);
      text(titles[i], pX, graphY+graphH+15);
      
      prevX = pX;
      prevY = pY;
      pX = pX + xW;
      i++;
    }
    stroke(0,0,0);
   }
   
   void drawLinesIn(){
     //advance transition
     transProgress += transSpeed;
     if (transProgress >= 1){
       transProgress = 1;
       currTransition = lgTransition.showing;
     }
     
    int pX = graphX;
    int i=0;
    int prevX=0, prevY=0;
    stroke(pointColor);
    for (int y : values){
      int pY = graphZeroY-y*yScale;

      //draw lines
      strokeWeight(5);
      if(i >0){
        line(prevX, prevY, lerp(prevX, pX, transProgress), lerp(prevY, pY, transProgress));
      }
      strokeWeight(1);
      
      //draw points
      fill(pointColor);
      ellipse(pX, pY, lerp(0,pD,transProgress), lerp(0,pD,transProgress));
      
      prevX = pX;
      prevY = pY;
      pX = pX + xW;
      i++;
    }
    stroke(0,0,0);
   }
   
   void drawLinesOut(){
     //advance transition
     transProgress += transSpeed;
     
    int pX = graphX;
    int i=0;
    int prevX=0, prevY=0;
    stroke(pointColor);
    for (int y : values){
      int pY = graphZeroY-y*yScale;

      //draw lines
      strokeWeight(5);
      if(i >0){
        line(prevX, prevY, lerp(prevX, pX, 1-transProgress), lerp(prevY, pY, 1-transProgress));
      }
      strokeWeight(1);
      
      //draw points
      fill(pointColor);
      ellipse(pX, pY, lerp(pD,0,transProgress), lerp(pD,0,transProgress));
      
      prevX = pX;
      prevY = pY;
      pX = pX + xW;
      i++;
    }
    stroke(0,0,0);
    if (transProgress >=1){
      doTransition(lgTransition.hidden);
    }
   }
   
}

boolean mouseInRect(int rX, int rY, int rW, int rH){
  //for given rect, check if mouse is over it
  if (mouseX > rX && mouseX < rX+rW && mouseY>rY && mouseY<rY+rH){
    return true;
  }
  return false;
}

int sign(int x){
  if(x>=0){
    return 1;
  } else {
    return -1;
  }
}