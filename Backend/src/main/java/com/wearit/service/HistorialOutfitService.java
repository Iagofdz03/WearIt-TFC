package com.wearit.service;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.wearit.model.HistorialOutfit;
import com.wearit.repository.HistorialOutfitRepository;

@Service
public class HistorialOutfitService {

    @Autowired
    private HistorialOutfitRepository historialRepository;

    public List<HistorialOutfit> listarPorUsuario(Long usuarioId) {
        return historialRepository.findByUsuarioIdOrderByFechaUsoDesc(usuarioId);
    }

    public HistorialOutfit guardar(HistorialOutfit historial) {
        return historialRepository.save(historial);
    }

    public void eliminar(Long id) {
        historialRepository.deleteById(id);
    }
}