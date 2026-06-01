package com.wearit.service;

import com.wearit.model.Favorito;
import com.wearit.model.Prenda;
import com.wearit.model.Outfit;
import com.wearit.model.Usuario;
import com.wearit.repository.FavoritoRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.util.List;

@Service
public class FavoritoService {

    @Autowired
    private FavoritoRepository favoritoRepository;

    public List<Favorito> getPrendasFavoritas(Long usuarioId) {
        return favoritoRepository.findByUsuarioIdAndPrendaIsNotNull(usuarioId);
    }

    public List<Favorito> getOutfitsFavoritos(Long usuarioId) {
        return favoritoRepository.findByUsuarioIdAndOutfitIsNotNull(usuarioId);
    }

    public boolean esPrendaFavorita(Long usuarioId, Long prendaId) {
        return favoritoRepository.existsByUsuarioIdAndPrendaId(usuarioId, prendaId);
    }

    public boolean esOutfitFavorito(Long usuarioId, Long outfitId) {
        return favoritoRepository.existsByUsuarioIdAndOutfitId(usuarioId, outfitId);
    }

    public void togglePrendaFavorita(Long usuarioId, Long prendaId) {
        if (favoritoRepository.existsByUsuarioIdAndPrendaId(usuarioId, prendaId)) {
            favoritoRepository.deleteByUsuarioIdAndPrendaId(usuarioId, prendaId);
        } else {
            Favorito f = new Favorito();
            f.setUsuario(new Usuario() {{ setId(usuarioId); }});
            f.setPrenda(new Prenda() {{ setId(prendaId); }});
            favoritoRepository.save(f);
        }
    }

    public void toggleOutfitFavorito(Long usuarioId, Long outfitId) {
        if (favoritoRepository.existsByUsuarioIdAndOutfitId(usuarioId, outfitId)) {
            favoritoRepository.deleteByUsuarioIdAndOutfitId(usuarioId, outfitId);
        } else {
            Favorito f = new Favorito();
            f.setUsuario(new Usuario() {{ setId(usuarioId); }});
            f.setOutfit(new Outfit() {{ setId(outfitId); }});
            favoritoRepository.save(f);
        }
    }
}