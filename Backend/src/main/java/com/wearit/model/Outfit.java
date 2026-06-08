package com.wearit.model;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.JoinTable;
import jakarta.persistence.ManyToMany;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "outfit")
@Data
@NoArgsConstructor
public class Outfit {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @JsonProperty(access = JsonProperty.Access.WRITE_ONLY)
    @ManyToOne
    @JsonIgnore
    @JoinColumn(name = "usuario_id", nullable = false)
    private Usuario usuario;

    private String nombre;
    private String ocasion;
    private Boolean esPublico = false;
    
    @Column(name = "foto_portada")
    private String fotoPortada;

    @Column(name = "fecha_creacion")
    private LocalDateTime fechaCreacion;

    // Relación con prendas (ManyToMany existente)
    @ManyToMany(fetch = FetchType.EAGER)
    @JoinTable(
        name = "outfit_prenda",
        joinColumns = @JoinColumn(name = "outfit_id"),
        inverseJoinColumns = @JoinColumn(name = "prenda_id")
    )
    private List<Prenda> prendas = new ArrayList<>();
    
    // ✅ RELACIÓN CON POSICIONES - ELIMINACIÓN EN CASCADA
    @OneToMany(mappedBy = "outfit", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<OutfitPrendaPosicion> posiciones = new ArrayList<>();
    
    // ✅ RELACIÓN CON FAVORITOS - ELIMINACIÓN EN CASCADA
    @OneToMany(mappedBy = "outfit", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Favorito> favoritos = new ArrayList<>();
    
    // ✅ RELACIÓN CON LIKES - ELIMINACIÓN EN CASCADA
    @OneToMany(mappedBy = "outfit", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Like> likes = new ArrayList<>();

    @PrePersist
    protected void onCreate() {
        fechaCreacion = LocalDateTime.now();
    }
}