package com.wearit.controller;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.wearit.model.Prenda;
import com.wearit.service.PrendaService;

@RestController
@RequestMapping("/api/prendas")
public class PrendaController {

    @Autowired
    private PrendaService prendaService;

    @GetMapping
    public List<Prenda> listar() {
        return prendaService.listarTodas();
    }

    @GetMapping("/usuario/{usuarioId}")
    public List<Prenda> listarPorUsuario(@PathVariable Long usuarioId) {
        return prendaService.listarPorUsuario(usuarioId);
    }

    @GetMapping("/{id}")
    public Prenda buscarPorId(@PathVariable Long id) {
        return prendaService.buscarPorId(id);
    }

    @PostMapping
    public Prenda crear(@RequestBody Prenda prenda) {
        return prendaService.crear(prenda);
    }

    @PutMapping("/{id}")
    public Prenda actualizar(@PathVariable Long id, @RequestBody Prenda datos) {
        return prendaService.actualizar(id, datos);
    }

    @DeleteMapping("/{id}")
    public void eliminar(@PathVariable Long id) {
        prendaService.eliminar(id);
    }
}
