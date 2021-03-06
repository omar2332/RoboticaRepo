/*
  Aquí está toda la lógica de la inteligencia artificial
  incluyendo la implementación de los algoritmos de búsqueda
  como Dijkstra.
*/

public class Controller {

  boolean inLongestPath = false;
  ArrayList<PVector> longestPath = new ArrayList<PVector>();
  ArrayList<PVector> mainSearch = new ArrayList<PVector>();
  ArrayList<PVector> mainPathGeneral = new ArrayList<PVector>();

  /* Se ejecuta cada fotograma, esta es la función principal
     desde la que se controlan las otras de búsqueda */
  void control() {
    mainSearch = new ArrayList<PVector>(); // Este arreglo se usa en dijkstra() para la búsqueda
    /* Se busca un camino principal hasta la comida usando dijkstra */
    mainPathGeneral = dijkstra(snake, int(food_pos.x/scl), int(food_pos.y/scl), true);
    
    if(mainPathGeneral.size() > 0) { // Si dicho camino es encontrado...
      if(justDijkstra) { // ...y si el modo de juego es solo búsqueda por Dijkstra
        int[] mainHead = {int(snake.pos[0].x/scl), int(snake.pos[0].y/scl)};
        chooseSpeed(snake, mainPathGeneral.get(1), mainHead); // Elegir movimiento normal
      } else { // ...pero si la búsqueda más compleja está activada, comprobar si la serpiente se encierra
        Snake virtualSnake = snake.copy(); // creando una serpiente virtual
        int[] currentHead = {0,0};
        
        // ...y mandándola a la comida. Este ciclo la mueve hasta la comida
        for (int i = 1; i < mainPathGeneral.size(); ++i) {
          currentHead[0] = int(virtualSnake.pos[0].x/scl);
          currentHead[1] = int(virtualSnake.pos[0].y/scl);
          chooseSpeed(virtualSnake, mainPathGeneral.get(i), currentHead);
          if(i == mainPathGeneral.size() - 1) {
            virtualSnake.eatsFood();
          }
          virtualSnake.update();
        }
        
        // y habiendo llegado la virtual a la comida busca el camino más a la cola
        ArrayList<PVector> tracebackBack = dijkstra(virtualSnake, int(virtualSnake.pos[virtualSnake.pos.length-1].x/scl), int(virtualSnake.pos[virtualSnake.pos.length-1].y/scl), false);
       
        int[] mainHead = {int(snake.pos[0].x/scl), int(snake.pos[0].y/scl)};

        if(tracebackBack.size() > 0) { // Si sí encuentra el camino hasta la cola
          // No se va a encerrar y puede elegir el camino normal que encontró al principio
          chooseSpeed(snake, mainPathGeneral.get(1), mainHead);
          inLongestPath = false;
        } else { // Pero si no lo encuentra lo mejor es buscar y seguir el más largo hasta la cola hasta que deje de encerrarse
          if(inLongestPath && longestPath.size() > 1) { // Si ya estaba recorriendo el camino más largo en el fotograma anterior
            chooseSpeed(snake, longestPath.get(1), mainHead); //simplemente continuar en él
            longestPath.remove(0);
          } 
        }
      }
    } else { // Pero si no encuentra el camino principal en el primer Dijsktra...
      if(justDijkstra) { // ...y si está en el modo justDijkstra, simplemente rotar si está a punto de chocarse
        if(snake.isInBody(PVector.add(snake.pos[0], snake.vel)) || isOutsideWorld(PVector.add(snake.pos[0], snake.vel))) {
          PVector rotateRight = snake.vel.copy().rotate(HALF_PI);
          rotateRight.x = int(rotateRight.x);
          rotateRight.y = int(rotateRight.y);
          PVector rotateLeft = snake.vel.copy().rotate(-HALF_PI);
          rotateLeft.x = int(rotateLeft.x);
          rotateLeft.y = int(rotateLeft.y);
          if(!snake.isInBody(new PVector(snake.pos[0].x + rotateRight.x, snake.pos[0].y + rotateRight.y)) && !isOutsideWorld(new PVector(snake.pos[0].x + rotateRight.x, snake.pos[0].y + rotateRight.y))) {
            println("Rotando a la derecha");
            snake.vel = rotateRight;
          } else if(!snake.isInBody(new PVector(snake.pos[0].x + rotateLeft.x, snake.pos[0].y + rotateLeft.y)) && !isOutsideWorld(new PVector(snake.pos[0].x + rotateLeft.x, snake.pos[0].y + rotateLeft.y))) {
            println("Rotando a la izquierda");
            snake.vel = rotateLeft;
          } else {
            println("No hay lugar para rotar");
          }
        }
      } else { //... y si no está en el modo justDijsktra
        /* Misma lógica de antes, buscar más largo hasta la cola. Esta es diferente
           de la vez anterior porque aquí se hace cuando no encontró el camino principal,
           mientras que en la otra se hace cuando si, de seguir el camino principal, 
           se terminaría encerrando. */
        int[] mainHead = {int(snake.pos[0].x/scl), int(snake.pos[0].y/scl)};
        if(inLongestPath && longestPath.size() > 1) {
          chooseSpeed(snake, longestPath.get(1), mainHead);
          longestPath.remove(0);
        } 
      }
    }
  }

  /* Búsqueda de Dijkstra, se usa tanto para la búsqueda de la serpiente
     principal como la de cualquier serpiente virtual */
  ArrayList<PVector> dijkstra(Snake currentSnake, int destinyX, int destinyY, boolean print) {
    /* Nodo es cada cuadrado del mapa, su valor es su distancia Manhattan a la 
       cabeza de la serpiente.*/
    
    int[][] nodes = new int[horSqrs][verSqrs];
    ArrayList<PVector> queue = new ArrayList<PVector>();
    boolean[][] checked = new boolean[horSqrs][verSqrs];


    //int[] firstNode = {int(currentSnake.pos[0].x/scl), int(currentSnake.pos[0].y/scl)};
    //PVector currentNode = new PVector(currentSnake.pos[0].x, currentSnake.pos[0].y);
    
    int[] firstNode = {destinyX, destinyY};
    PVector currentNode = new PVector(destinyX, destinyY);
    
    
    
    
    // Inicializar todos los nodos con un valor infinito, excepto el primero, que es 0
    for (int i = 0; i < horSqrs; ++i) {
      for (int ii = 0; ii < verSqrs; ++ii) {
        if(firstNode[0] != i || firstNode[1] != ii) {
          nodes[i][ii] = Integer.MAX_VALUE;
          checked[i][ii] = false;
        } else {
          nodes[i][ii] = 0;
          checked[i][ii] = true;
        }
      }
    }
    
    // Comenzar a añadir nodos al queue que los evalúa uno por uno para asignar valores
    queue.add(new PVector(firstNode[0], firstNode[1]));
    boolean somethingInQueue = true;
    int i = 0;

    /* En este ciclo se llenan los valores de todos los nodos, es decir, la distancia
       Manhattan a todos los cuadrados en el mapa a los que puede llegar. Para esto se
       se va comprobando cada uno de los nodos.  */
    while(somethingInQueue) {
      i++;

      int horIndex = int(queue.get(0).x);
      int verIndex = int(queue.get(0).y);
      
      int value = Integer.MAX_VALUE;

      /* A cada nodo se le comprueban los cuatro nodos a los lados y el valor se asigna dependiendo
         del que tenga el menor */
      value = checkSideNode(horIndex, 0, horIndex-1, verIndex, value, nodes, queue, currentSnake); // izquierda
      value = checkSideNode(-horIndex, 1-horSqrs, horIndex+1, verIndex, value, nodes, queue, currentSnake); // derecha
      value = checkSideNode(verIndex, 0, horIndex, verIndex-1, value, nodes, queue, currentSnake); // arriba
      value = checkSideNode(-verIndex, 1-verSqrs, horIndex, verIndex+1, value, nodes, queue, currentSnake); // abajo

      queue.remove(0); // se remueve el nodo actual del queue porque es el que se está comprobando
      
      if(int(horIndex) != firstNode[0] || int(verIndex) != firstNode[1]) { // Si el nodo actual no es el primero...
        if(!renderingMainSearch) {
          mainSearch.add(new PVector(horIndex, verIndex)); // Este arreglo solo se usa para dibujar la búsqueda cada que come
        }
        nodes[horIndex][verIndex] = value; // ...se le asigna el valor
        checked[horIndex][verIndex] = true;
        
      }
      
      

      //if( (int(horIndex) == destinyX && int(verIndex) == destinyY) || queue.size() == 0) {
      if(  (int(horIndex) == int(currentSnake.pos[0].x/scl) && int(verIndex) == int(currentSnake.pos[0].y/scl)) || queue.size() == 0) {  
        somethingInQueue = false;
        if(print) {
          
          println("===================================================");
          println("===================================================");
          //printScreen(nodes);
          
        }
      }
    }
    //println(mainSearch);
    //println("===================================================");

    /* Habiendo asignado a todos los nodos un valor, comienza a volverse desde el nodo
       con la comida (destinyX, destinyY) hasta la cabeza de la serpiente */
    ArrayList<PVector> tracebackNodes = new ArrayList<PVector>();
    ArrayList<PVector> tracebackNodesReverse = new ArrayList<PVector>();
    //int[] tracebackNode = {destinyX, destinyY};
    
    int[] tracebackNode = {int(currentSnake.pos[0].x/scl), int(currentSnake.pos[0].y/scl)};
    tracebackNodes = new ArrayList<PVector>();
    tracebackNodes.add(new PVector(tracebackNode[0], tracebackNode[1]));
    boolean closed = false;
  
    // Se devuelve buscando cada vez el nodo con el menor valor
    while(tracebackNode[0] != firstNode[0] || tracebackNode[1] != firstNode[1]) {
      PVector move = lowestNextTo(tracebackNode[0], tracebackNode[1], nodes);
      if(move.x == -1 && move.y == -1) {
        
        return new ArrayList<PVector>();
      }
      tracebackNodes.add(0, move);
      tracebackNode[0] = int(move.x);
      tracebackNode[1] = int(move.y);
    }

    renderingMainSearch = true; // cuando la búsqueda se acaba de hacer, se usan los siguientes frames para dibujarla
    println(tracebackNodes);
    println(destinyX, destinyY);
    println(int(currentSnake.pos[0].x/scl), int(currentSnake.pos[0].y/scl));

    
    for(i = tracebackNodes.size()-1 ; i>=0;i--){
      tracebackNodesReverse.add(  tracebackNodes.get(i) );
    }
      
    
    return tracebackNodesReverse; // si no encuentra un camino, esto retorna vacío
  }

  int checkSideNode(int checked, int checkTo, int checkHor, int checkVer, int cValue, int[][] nodes, ArrayList<PVector> queue, Snake cSnake) {
    if(checked > checkTo) { // Comprobar que estén dentro del mundo
      if(nodes[checkHor][checkVer] < Integer.MAX_VALUE) { // Y que su valor no sea infinito
        if(nodes[checkHor][checkVer] < cValue) { // Si el valor del nodo de lado es menor al nodo central
          return nodes[checkHor][checkVer] + 1;
        }
      } else { // pero si su valor si es infinito
        if(!cSnake.isInBody(checkHor, checkVer)) {
          if(!queue.contains(new PVector(checkHor, checkVer))) {
            queue.add(new PVector(checkHor, checkVer)); // se añade al queue, porque significa que no está comprobado
            // con esta última línea se asegura de que el queue pase por todos los nodos
          }
        }
      }
    }
    return cValue;
  }

  // Comprobar cuál es el nodo de menor valor al que tiene las coords. x, y
  PVector lowestNextTo(int x, int y, int[][] nodes) {
    int lowestXInd = 0;
    int lowestYInd = 0;
    int lowestValue = Integer.MAX_VALUE;

    if(x > 0) {
      if(nodes[x-1][y] < lowestValue) {

        lowestValue = nodes[x-1][y] + 1;
        lowestXInd = x-1;
        lowestYInd = y;
      }
    }
    if(x < horSqrs - 1) {
      if(nodes[x+1][y] < lowestValue - 1) {

        lowestValue = nodes[x+1][y] + 1;
        lowestXInd = x+1;
        lowestYInd = y;
      }
    }
    if(y > 0) {
      if(nodes[x][y-1] < lowestValue - 1) {

        lowestValue = nodes[x][y-1] + 1;
        lowestXInd = x;
        lowestYInd = y-1;
      }
    }
    if(y < verSqrs - 1) {
      if(nodes[x][y+1] < lowestValue - 1) {

        lowestValue = nodes[x][y+1] + 1;
        lowestXInd = x;
        lowestYInd = y+1;
      }
    }
    

    return new PVector(lowestXInd, lowestYInd);
    
  }

  

  // Función que renderiza la búsqueda principal (se ejecuta durante varios frames)
  void renderMainSearch() {
    if(mainSearch.size() > 0) {
      frameRate(100);
      fill(searchcol);
      noStroke();
      rect(mainSearch.get(0).x*scl + 1, mainSearch.get(0).y*scl + 1, scl - 1, scl - 1);
      if(mainSearch.get(0).x*scl == food_pos.x && mainSearch.get(0).y*scl == food_pos.y) {
        fill(shortpathcol);
        frameRate(1);
        for (int i= mainPathGeneral.size()-1;i >=0;i--) {
          
          rect(mainPathGeneral.get(i).x*scl + 1, mainPathGeneral.get(i).y*scl + 1, scl - 1, scl - 1);
                
        }
        
        
      }
      
      
      mainSearch.remove(0);
      
    } else {
      renderingMainSearch = false;
    }
    
  }
  

  // Elegir la dirección de movimiento de la serpiente
  void chooseSpeed(Snake cSnake, PVector move, int[] cHead) {

    int horMove = int(move.x) - cHead[0];
    int verMove = int(move.y) - cHead[1];

    if(horMove == -1 && verMove == 0) {
      cSnake.vel.x = -scl;
      cSnake.vel.y = 0;
    } else if(horMove == 1 && verMove == 0) {
      cSnake.vel.x = scl;
      cSnake.vel.y = 0;
    } else if(horMove == 0 && verMove == -1) {
      cSnake.vel.x = 0;
      cSnake.vel.y = -scl;
    } else if(horMove == 0 && verMove == 1) {
      cSnake.vel.x = 0;
      cSnake.vel.y = scl;
    }
  }

  // Imprimir los valores de cada nodo del mapa
  void printScreen(int[][] nodes) {
    for (int o = 0; o < verSqrs; ++o) {
      for (int oo = 0; oo < horSqrs; ++oo) {
        if(nodes[oo][o] == Integer.MAX_VALUE) {
          print("i  ");
        } else {
          if(nodes[oo][o] < 10) {
            print(nodes[oo][o] + "  ");
          } else if(nodes[oo][o] < 100) {
            print(nodes[oo][o] + " ");
          }
        }
      }
      print('\n');
    }
  }
}
