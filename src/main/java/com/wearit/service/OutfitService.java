package com.wearit.service;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.wearit.model.Outfit;
import com.wearit.repository.FavoritoRepository;
import com.wearit.repository.HistorialOutfitRepository;
import com.wearit.repository.LikeRepository;
import com.wearit.repository.OutfitPrendaPosicionRepository;
import com.wearit.repository.OutfitRepository;

@Service
public class OutfitService {

    @Autowired
    private OutfitRepository outfitRepository;
    
    @Autowired
    private LikeRepository likeRepository;

    @Autowired
    private HistorialOutfitRepository historialRepository;
    
    // ✅ NUEVO: Repositorio para posiciones
    @Autowired
    private OutfitPrendaPosicionRepository posicionRepository;
    
    // ✅ NUEVO: Repositorio para favoritos
    @Autowired
    private FavoritoRepository favoritoRepository;

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
        outfit.setFotoPortada(datos.getFotoPortada());
        return outfitRepository.save(outfit);
    }

    @Transactional
    public void eliminar(Long id) {
        // 1. Eliminar posiciones
        posicionRepository.deleteByOutfitId(id);
        
        // 2. Eliminar favoritos
        favoritoRepository.deleteByOutfitId(id);
        
        // 3. Eliminar likes
        likeRepository.deleteByOutfitId(id);
        
        // 4. Eliminar historial
        historialRepository.deleteByOutfitId(id);
        
        // 5. Finalmente eliminar el outfit
        outfitRepository.deleteById(id);
    }
}