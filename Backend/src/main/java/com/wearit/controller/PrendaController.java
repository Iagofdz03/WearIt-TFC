package com.wearit.controller;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

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

    // Endpoint de filtrado que Flutter usa con query params
    @GetMapping("/usuario/{usuarioId}/filtrar")
    public List<Prenda> filtrar(
            @PathVariable Long usuarioId,
            @RequestParam(required = false) String tipo,
            @RequestParam(required = false) String color,
            @RequestParam(required = false) String estilo,
            @RequestParam(required = false) String temporada,
            @RequestParam(required = false) String estampado,
            @RequestParam(required = false) String nombre) {
        return prendaService.filtrar(usuarioId, tipo, color, estilo, temporada, estampado, nombre);
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