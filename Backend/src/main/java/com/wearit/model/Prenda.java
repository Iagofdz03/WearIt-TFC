package com.wearit.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import lombok.Data;
import lombok.NoArgsConstructor;
import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonProperty;

@Entity
@Table(name = "prenda")
@Data
@NoArgsConstructor
public class Prenda {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @JsonProperty(access = JsonProperty.Access.WRITE_ONLY)
    @ManyToOne
    @JsonIgnore
    @JoinColumn(name = "usuario_id", nullable = false)
    private Usuario usuario;

    private String nombre;
    private String tipo;
    private String color;
    private String estilo;
    private String temporada;
    private String estampado;
    private String fotoUrl;
    
    @Column(name = "foto_portada")
    private String fotoPortada;

    @Column(name = "fecha_anadida")
    private java.time.LocalDateTime fechaAnadida;

    @PrePersist
    protected void onCreate() {
        fechaAnadida = java.time.LocalDateTime.now();
    }
}
