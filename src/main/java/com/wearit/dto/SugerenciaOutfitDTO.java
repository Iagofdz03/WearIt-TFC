package com.wearit.dto;

import com.wearit.model.Prenda;
import java.util.List;

public class SugerenciaOutfitDTO {
    private String nombre;
    private List<Prenda> prendas;
    private String explicacion;
    
    // Constructor
    public SugerenciaOutfitDTO(String nombre, List<Prenda> prendas, String explicacion) {
        this.nombre = nombre;
        this.prendas = prendas;
        this.explicacion = explicacion;
    }
    
    // Getters
    public String getNombre() { return nombre; }
    public List<Prenda> getPrendas() { return prendas; }
    public String getExplicacion() { return explicacion; }
}
