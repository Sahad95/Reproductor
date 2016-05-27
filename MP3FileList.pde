import controlP5.*;
import ddf.minim.*;
import ddf.minim.effects.*;

import java.util.*;
import java.net.InetAddress;
import javax.swing.*;
import javax.swing.filechooser.FileFilter;
import javax.swing.filechooser.FileNameExtensionFilter;

import org.elasticsearch.action.admin.indices.exists.indices.IndicesExistsResponse;
import org.elasticsearch.action.admin.cluster.health.ClusterHealthResponse;
import org.elasticsearch.action.index.IndexRequest;
import org.elasticsearch.action.index.IndexResponse;
import org.elasticsearch.action.search.SearchResponse;
import org.elasticsearch.action.search.SearchType;
import org.elasticsearch.client.Client;
import org.elasticsearch.common.settings.Settings;
import org.elasticsearch.node.Node;
import org.elasticsearch.node.NodeBuilder;


Minim minim;
AudioPlayer cancion;
ControlP5 pl;
float vol=0;
Chart myChart;
Convolver lpf;

// Constantes para referir al nombre del indice y el tipo
static String INDEX_NAME = "canciones";
static String DOC_TYPE = "cancion";

ControlP5 cp5;
ScrollableList list;

Client client;
Node node;

void setup() {
  size(500, 300);
  background(255);
  noStroke();
  cp5 = new ControlP5(this);

  // Configuracion basica para ElasticSearch en local
  Settings.Builder settings = Settings.settingsBuilder();
  // Esta carpeta se encontrara dentro de la carpeta del Processing
  settings.put("path.data", "esdata");
  settings.put("path.home", "/");
  settings.put("http.enabled", false);
  settings.put("index.number_of_replicas", 0);
  settings.put("index.number_of_shards", 1);

  // Inicializacion del nodo de ElasticSearch
  node = NodeBuilder.nodeBuilder()
    .settings(settings)
    .clusterName("mycluster")
    .data(true)
    .local(true)
    .node();

  // Instancia de cliente de conexion al nodo de ElasticSearch
  client = node.client();

  // Esperamos a que el nodo este correctamente inicializado
  ClusterHealthResponse r = client.admin().cluster().prepareHealth().setWaitForGreenStatus().get();
  println(r);

  // Revisamos que nuestro indice (base de datos) exista
  IndicesExistsResponse ier = client.admin().indices().prepareExists(INDEX_NAME).get();
  if (!ier.isExists()) {
    // En caso contrario, se crea el indice
    client.admin().indices().prepareCreate(INDEX_NAME).get();
  }

  // Agregamos a la vista un boton de importacion de archivos
  cp5.addButton("importFiles")
    .setPosition(10, 10)
    .setLabel("Importar archivos");

  // Agregamos a la vista una lista scrollable que mostrara las canciones
  list = cp5.addScrollableList("playlist")
    .setPosition(0, 40)
    .setSize(500, 400)
    .setBarHeight(20)
    .setItemHeight(20)
    .setType(ScrollableList.LIST);

  // Cargamos los archivos de la base de datos
  loadFiles();
  //creacion de botones
  pl.addLabel("label")
    .setColorBackground( color(255, 200, 200) )
    .setPosition(20, 170)
    .setSize(200, 40)
    .setFont(createFont("arial", 20))
    //.setAutoClear(false)
    ;

  pl.addButton("reproducir")
    .setColorBackground( color(255, 200, 200) )
    .setPosition(200, 250)
    .setSize(40, 40)
    .setImages(loadImage("play.png"), loadImage("play.png"), loadImage("play.png"))
    ;
  pl.addButton("pausar")
    .setColorBackground( color(255, 200, 200) )
    .setPosition(250, 250)
    .setSize(40, 40)
    .setImages(loadImage("pause.png"), loadImage("pause.png"), loadImage("pause.png"))
    ;
  pl.addButton("detener")
    .setColorBackground( color(255, 200, 200) )
    .setPosition(300, 250)
    .setSize(40, 40)
    .setImages(loadImage("stop.png"), loadImage("stop.png"), loadImage("stop.png"))
    ;
  pl.addButton("Subir_Volumen")
    .setColorBackground( color(0, 200, 200) )
    .setPosition(500, 100)
    .setSize(40, 40)
    .setImages(loadImage("subVo.png"), loadImage("subVo.png"), loadImage("subVo.png"))
    ;
  pl.addButton("Bajar_Volumen")
    .setColorBackground( color(0, 200, 200) )
    .setPosition(500, 150)
    .setSize(40, 40)
    .setImages(loadImage("bajVo.png"), loadImage("bajVo.png"), loadImage("bajVo.png"))
    ;
  pl.addButton("Mute")
    .setColorBackground( color(0, 200, 200) )
    .setPosition(500, 50)
    .setSize(40, 40) 
    .setImages(loadImage("Mute.png"), loadImage("Mute.png"), loadImage("Mute.png"))
    ;

  pl.addButton("Abrir")
    .setColorBackground( color(255, 200, 200) )
    .setPosition(500, 250)
    .setSize(40, 40)
    .setImages(loadImage("Musica.png"), loadImage("Musica.png"), loadImage("Musica.png"))
    ;
}

void draw() {
}
//Funciones de los botones
public void reproducir() {
  cancion.play();
  fill(10, 225, 10);
  println("reproducir");
}
public void pausar() {
  cancion.pause(); 
  println("pausar");
}
public void detener() {
  cancion.rewind();
  cancion.pause();
  println("detener");
}

public void Mute() { 
  cancion.mute();
  println("Mute");
}


public void Abrir() {  
  selectInput("Select a file to process:", "fileSelected");
  cancion.pause();
  println("Abrir");
}

public void Subir_Volumen() {
  cancion.unmute();
  cancion.setGain(vol+=3);
  println("Subir_Volumen");
}
public void Bajar_Volumen() {
  cancion.unmute();
  cancion.setGain(vol-=3);
  println("Bajar_Volumen");
}
void fileSelected(File selection) {
  if (selection == null) {

    println("Window was closed or the user hit cancel.");
  } else {
    println("User selected " + selection.getAbsolutePath());
    minim= new Minim(this);
    cancion=minim.loadFile(selection.getAbsolutePath(), 500);
  }
}
public void controlEvent(ControlEvent event) {
  println(event.getController().getName());
}

void importFiles() {
  // Selector de archivos
  JFileChooser jfc = new JFileChooser();
  // Agregamos filtro para seleccionar solo archivos .mp3
  jfc.setFileFilter(new FileNameExtensionFilter("MP3 File", "mp3"));
  // Se permite seleccionar multiples archivos a la vez
  jfc.setMultiSelectionEnabled(true);
  // Abre el dialogo de seleccion
  jfc.showOpenDialog(null);

  // Iteramos los archivos seleccionados
  for (File f : jfc.getSelectedFiles()) {
    // Si el archivo ya existe en el indice, se ignora
    GetResponse response = client.prepareGet(INDEX_NAME, DOC_TYPE, f.getAbsolutePath()).setRefresh(true).execute().actionGet();
    if (response.isExists()) {
      continue;
    }

    // Cargamos el archivo en la libreria minim para extrar los metadatos
    Minim minim = new Minim(this);
    AudioPlayer song = minim.loadFile(f.getAbsolutePath());
    AudioMetaData meta = song.getMetaData();

    // Almacenamos los metadatos en un hashmap
    Map<String, Object> doc = new HashMap<String, Object>();
    doc.put("author", meta.author());
    doc.put("title", meta.title());
    doc.put("path", f.getAbsolutePath());

    try {
      // Le decimos a ElasticSearch que guarde e indexe el objeto
      client.prepareIndex(INDEX_NAME, DOC_TYPE, f.getAbsolutePath())
        .setSource(doc)
        .execute()
        .actionGet();

      // Agregamos el archivo a la lista
      addItem(doc);
    } 
    catch(Exception e) {
      e.printStackTrace();
    }
  }
}

// Al hacer click en algun elemento de la lista, se ejecuta este metodo
void playlist(int n) {
  println(list.getItem(n));
}

void loadFiles() {
  try {
    // Buscamos todos los documentos en el indice
    SearchResponse response = client.prepareSearch(INDEX_NAME).execute().actionGet();

    // Se itera los resultados
    for (SearchHit hit : response.getHits().getHits()) {
      // Cada resultado lo agregamos a la lista
      addItem(hit.getSource());
    }
  } 
  catch(Exception e) {
    e.printStackTrace();
  }
}

// Metodo auxiliar para no repetir codigo
void addItem(Map<String, Object> doc) {
  // Se agrega a la lista. El primer argumento es el texto a desplegar en la lista, el segundo es el objeto que queremos que almacene
  list.addItem(doc.get("author") + " - " + doc.get("title"), doc);
}