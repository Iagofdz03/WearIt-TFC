package com.wearit.service;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.wearit.model.Outfit;
import com.wearit.repository.OutfitRepository;

@Service
public class OutfitService {

    @Autowired
    private OutfitRepository outfitRepository;

    public List<Outfit> listarTodos() {
        return outfitRepository.findAll();
    }

    public List<Outfit> listarPorUsuario(Long usuarioId) {
        return outfitRepository.findByUsuarioId(usuarioId);
    }

    public List<Outfit> listarPublicos() {
        return outfitRepository.findByEsPublicoTrue();
    }

    public Outfit buscarPorId(Long id) {
        return outfitRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Outfit no encontrado"));
    }

    public Outfit crear(Outfit outfit) {
        return outfitRepository.save(outfit);
    }

    public Outfit actualizar(Long id, Outfit datos) {
        Outfit outfit = buscarPorId(id);
        outfit.setNombre(datos.getNombre());
        outfit.setOcasion(datos.getOcasion());
        outfit.setEsPublico(datos.getEsPublico());
        outfit.setPrendas(datos.getPrendas());
        return outfitRepository.save(outfit);
    }

    public void eliminar(Long id) {
        outfitRepository.deleteById(id);
    }
}
