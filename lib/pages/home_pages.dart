import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class HomePage extends StatefulWidget{
  const HomePage({Key? key}) : super(key:  key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>{

  final _linha = <String>[];
  StreamSubscription<Position>? _subscription;
  Position? _ultimaPosicaoOpbtida;
  double _distanciaTotalPercorrida = 0;

  bool get _monitorandoLocalizacao => _subscription != null;


  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: _criarAppBar(),
      body: _criarBody(),
    );
  }

  AppBar _criarAppBar(){
    return AppBar(
      title: Text('Usando GPS'),
    );
  }

  Widget _criarBody() => Padding(
    padding: EdgeInsets.all(10),
    child: Column(
      children: [
        ElevatedButton(
          onPressed: _obterUltimaLocalizacao,
          child: Text('Obter a ultima localização conhecida'),
        ),
        ElevatedButton(
          onPressed: _obterLocalizacaoAtual,
          child: Text('Obter a localização atual do dispositivo'),
        ),
        ElevatedButton(
          onPressed: _monitorandoLocalizacao ? _pararMonitoramento : _iniciarMonitoramento,
          child: Text(_monitorandoLocalizacao ? 'Parar o Monitoramento': 'Iniciar Monitoramento'),
        ),
        ElevatedButton(
          onPressed: _limpaLog,
          child: Text('Limpar log'),
        ),
        Divider(),
        Expanded(
          child: ListView.builder(
              shrinkWrap: true,
              itemCount: _linha.length,
              itemBuilder: (_, index) => Padding(
                padding: EdgeInsets.all(5),
                child: Text(_linha[index]),
              )
          ),
        ),
      ],
    ),
  );

  void _obterUltimaLocalizacao() async {
    bool permissoesPermitidas = await _permissoesPermitidas();
    if(!permissoesPermitidas){
      return;
    }
    Position? position = await Geolocator.getLastKnownPosition();
    setState(() {
      if(position == null){
        _linha.add('Nenhuma localização registrada');
      }else{
        _linha.add('Latitude: ${position.latitude}  |  Longetude: ${position.longitude}');
      }
    });
  }

  void _obterLocalizacaoAtual() async {
    bool servicoHabilitado = await _servicoHabilitado();
    if(!servicoHabilitado){
      return;
    }
    bool permissoesPermitidas = await _permissoesPermitidas();
    if(!permissoesPermitidas){
      return;
    }
    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _linha.add('Latitude: ${position.latitude}  |  Longetude: ${position.longitude}');
    });

  }

  void _iniciarMonitoramento() async {
    bool servicoHabilitado = await _servicoHabilitado();
    if(!servicoHabilitado){
      return;
    }
    bool permissoesPermitidas = await _permissoesPermitidas();
    if(!permissoesPermitidas){
      return;
    }

    LocationSettings locationSettings = LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 100);

    _subscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
            (Position position) {
          setState(() {
            _linha.add('Latitude: ${position.latitude}  |  Longetude: ${position.longitude}');
          });
          if(_ultimaPosicaoOpbtida != null){
            final distancia = Geolocator.distanceBetween(
                _ultimaPosicaoOpbtida!.latitude, _ultimaPosicaoOpbtida!.longitude,
                position.latitude, position.longitude);
            _distanciaTotalPercorrida += distancia;
          }
          _linha.add('Distancia percorrida: ${_distanciaTotalPercorrida.toInt()} M');
          _ultimaPosicaoOpbtida = position;
        });
  }

  void _pararMonitoramento() {
    _subscription!.cancel();
    setState(() {
      _subscription = null;
      _ultimaPosicaoOpbtida = null;
      _distanciaTotalPercorrida = 0;
    });
  }

  Future<bool> _servicoHabilitado() async {
    bool servicoHabilotado = await Geolocator.isLocationServiceEnabled();
    if(!servicoHabilotado){
      await _mostrarMensagemDialog('Para utilizar esse recurso, você deverá habilitar o serviço de localização '
          'no dispositivo');
      Geolocator.openLocationSettings();
      return false;
    }
    return true;
  }

  Future<bool> _permissoesPermitidas() async {
    LocationPermission permissao = await Geolocator.checkPermission();
    if(permissao == LocationPermission.denied){
      permissao = await Geolocator.requestPermission();
      if(permissao == LocationPermission.denied){
        _mostrarMensagem('Não será possível utilizar o recusro por falta de permissão');
        return false;
      }
    }
    if(permissao == LocationPermission.deniedForever){
      await _mostrarMensagemDialog(
          'Para utilizar esse recurso, você deverá acessar as configurações '
              'do appe permitir a utilização do serviço de localização');
      Geolocator.openAppSettings();
      return false;
    }
    return true;

  }

  void _mostrarMensagem(String mensagem){
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  Future<void> _mostrarMensagemDialog(String mensagem) async{
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Atenção'),
        content: Text(mensagem),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _limpaLog(){
    setState(() {
      _linha.clear();
    });
  }
}