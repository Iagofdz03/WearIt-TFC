package com.wearit.service;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.wearit.model.Prenda;
import com.wearit.repository.PrendaRepository;

@Service
public class PrendaService {

    @Autowired
    private PrendaRepository prendaRepository;

    public List<Prenda> listarTodas() {
        return prendaRepository.findAll();
    }

    public List<Prenda> listarPorUsuario(Long usuarioId) {
        return prendaRepository.findByUsuarioId(usuarioId);
    }

    public List<Prenda> filtrar(Long usuarioId, String tipo, String color,
                                 String estilo, String temporada, String nombre) {
        return prendaRepository.filtrar(usuarioId, tipo, color, estilo, temporada, nombre);
    }

    public Prenda buscarPorId(Long id) {
        return prendaRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Prenda no encontrada"));
    }

    public Prenda crear(Prenda prenda) {
        return prendaRepository.save(prenda);
    }

    public Prenda actualizar(Long id, Prenda datos) {
        Prenda prenda = buscarPorId(id);
        prenda.setNombre(datos.getNombre());
        prenda.setTipo(datos.getTipo());
        prenda.setColor(datos.getColor());
        prenda.setEstilo(datos.getEstilo());
        prenda.setTemporada(datos.getTemporada());
        prenda.setFotoUrl(datos.getFotoUrl());
        prenda.setFotoPortada(datos.getFotoPortada());
        return prendaRepository.save(prenda);
    }

    public void eliminar(Long id) {
        try {
            prendaRepository.deleteById(id);
        } catch (Exception e) {
            throw new RuntimeException("Esta prenda pertenece a un outfit. Elimina primero el outfit.");
        }
    }
}
