--
-- PostgreSQL database dump
--

-- Dumped from database version 16.2 (Debian 16.2-1.pgdg120+2)
-- Dumped by pg_dump version 16.2

-- Started on 2024-06-15 22:03:34 UTC

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 280 (class 1255 OID 32769)
-- Name: fin_clientes_nuevos(text, text, text); Type: FUNCTION; Schema: public; Owner: djBackends
--

CREATE FUNCTION public.fin_clientes_nuevos(filtro text, fecha_inicio text, fecha_fin text) RETURNS TABLE(total_clientes bigint, fecha date)
    LANGUAGE plpgsql
    AS $$
BEGIN
RETURN QUERY
	SELECT
		COUNT(*) AS total_clientes , 
		CASE WHEN filtro = 'fechas'  THEN  
			CAST(DATE(fecha_registro) AS DATE) 
		ELSE
			CAST(DATE_TRUNC('month', fecha_registro) AS DATE)
		END AS fecha
	FROM CLIENTE
	WHERE 
		CASE WHEN filtro = 'fechas' THEN
			DATE(fecha_registro) >= fecha_inicio::date AND DATE(fecha_registro) <= fecha_fin::date
			END
		OR
		CASE WHEN filtro = 'ano' THEN
			DATE_PART('year', fecha_registro) = DATE_PART('year' , current_date)
			END
		GROUP BY 
		CASE WHEN filtro = 'fechas' THEN  
            CAST(DATE(fecha_registro) AS DATE)  
        ELSE
			CAST(DATE_TRUNC('month', fecha_registro) AS DATE)
        END;
		
END;
$$;


ALTER FUNCTION public.fin_clientes_nuevos(filtro text, fecha_inicio text, fecha_fin text) OWNER TO "djBackends";

--
-- TOC entry 292 (class 1255 OID 32770)
-- Name: fin_clientes_nuevos_2(text, text, text); Type: FUNCTION; Schema: public; Owner: djBackends
--

CREATE FUNCTION public.fin_clientes_nuevos_2(filtro text, fecha_inicio text, fecha_fin text) RETURNS TABLE(total_clientes bigint, fecha date, suma integer, porcentaje numeric)
    LANGUAGE plpgsql
    AS $$
DECLARE
    total_total_clientes bigint;
BEGIN
    -- Obtenemos la suma total de clientes
    SELECT COUNT(*) INTO total_total_clientes
    FROM CLIENTE
    WHERE 
        (filtro = 'fechas' AND DATE(fecha_registro) >= fecha_inicio::date AND DATE(fecha_registro) <= fecha_fin::date)
        OR
        (filtro = 'anual' AND DATE_PART('year', fecha_registro) = DATE_PART('year' , current_date));

    -- Consulta para obtener los datos de cada cliente con su respectivo porcentaje
    RETURN QUERY
    SELECT
        COUNT(*) AS total_clientes, 
        CASE 
            WHEN filtro = 'fechas' THEN CAST(DATE(fecha_registro) AS DATE) 
            ELSE CAST(DATE_TRUNC('month', fecha_registro) AS DATE)
        END AS fecha,
        CAST(SUM(1) AS int) AS suma,
        CAST(SUM(1) * 100.0 / total_total_clientes AS numeric) AS porcentaje
    FROM 
        CLIENTE
    WHERE 
        (filtro = 'fechas' AND DATE(fecha_registro) >= fecha_inicio::date AND DATE(fecha_registro) <= fecha_fin::date)
        OR
        (filtro = 'anual' AND DATE_PART('year', fecha_registro) = DATE_PART('year' , current_date))
    GROUP BY 
        CASE 
            WHEN filtro = 'fechas' THEN CAST(DATE(fecha_registro) AS DATE)  
            ELSE CAST(DATE_TRUNC('month', fecha_registro) AS DATE)
        END;
END;
$$;


ALTER FUNCTION public.fin_clientes_nuevos_2(filtro text, fecha_inicio text, fecha_fin text) OWNER TO "djBackends";

--
-- TOC entry 294 (class 1255 OID 40961)
-- Name: fin_tiempo_registro(text, text, text); Type: FUNCTION; Schema: public; Owner: djBackends
--

CREATE FUNCTION public.fin_tiempo_registro(filtro text, date_start text, date_end text) RETURNS TABLE(fecha date, tiempo_total_en_segundos numeric, horas integer, minutos numeric, segundos numeric, tiempo_total_formateado text)
    LANGUAGE plpgsql
    AS $$
BEGIN
RETURN QUERY
	SELECT 
	    CASE 
            WHEN filtro = 'fechas' THEN CAST(DATE(fecha_registro) AS DATE) 
            ELSE CAST(DATE_TRUNC('month', fecha_registro) AS DATE)
        END AS fecha,
	    ROUND(SUM(EXTRACT(EPOCH FROM tiempo_estimado::interval))) AS tiempo_total_en_segundos,
	    (SUM(EXTRACT(EPOCH FROM tiempo_estimado::interval)) / 3600)::INT AS horas,
	    ROUND(((SUM(EXTRACT(EPOCH FROM tiempo_estimado::interval)) % 3600) / 60) , 2) AS minutos,
	    ROUND((SUM(EXTRACT(EPOCH FROM tiempo_estimado::interval)) % 60) , 2) AS segundos,
	    (SUM(EXTRACT(EPOCH FROM tiempo_estimado::interval)) / 3600)::INT || ' horas ' ||
	    ((SUM(EXTRACT(EPOCH FROM tiempo_estimado::interval)) % 3600) / 60)::INT || ' minutos ' ||
	    (SUM(EXTRACT(EPOCH FROM tiempo_estimado::interval)) % 60)::INT || ' segundos' AS tiempo_total_formateado
	FROM 
	    public.cita
	WHERE 
		tiempo_estimado is not null AND
	    (filtro = 'fechas' AND DATE(fecha_registro::DATE ) >= date_start::date AND DATE(fecha_registro::DATE ) <= date_end::date)
	    OR
	    (filtro = 'anual' AND DATE_PART('year', fecha_registro::DATE ) = DATE_PART('year' , current_date))
	GROUP BY 
	   CASE 
            WHEN filtro = 'fechas' THEN CAST(DATE(fecha_registro) AS DATE) 
            ELSE CAST(DATE_TRUNC('month', fecha_registro) AS DATE)
        END
	ORDER BY 
	    fecha asc;
end;
$$;


ALTER FUNCTION public.fin_tiempo_registro(filtro text, date_start text, date_end text) OWNER TO "djBackends";

--
-- TOC entry 293 (class 1255 OID 32771)
-- Name: fn_listar_cita(integer); Type: FUNCTION; Schema: public; Owner: djBackends
--

CREATE FUNCTION public.fn_listar_cita(pid integer) RETURNS TABLE(id bigint, key_veterinario bigint, key_cliente bigint, key_servicio bigint, key_mascota bigint, sexo_mascota text, key_tipo_cita bigint, key_estado bigint, fecha_inicio date, hora_inicio text, hora_fin text, motivo_consulta text, observacion_sistema text, diagnostico text, recomendacion text, nombre_completo_veterinario text, dni_vt text, num_cel_vt text, correo_vt text, dni_cl text, correo text, nombre_completo_cliente text, num_cel text, nombre_mascota text, nombre_raza text, especie text, nombre_servicio text, precio double precision, duracion text, tipo_cita text, key_tipo_servicio bigint, tipo_servicio text, estado text, color text, icon text, edad text)
    LANGUAGE plpgsql
    AS $$
BEGIN
RETURN QUERY
SELECT
ct.id,
vt.id as key_veterinario,
cl.id as key_cliente,
ser.id as key_servicio,
mas.id as key_mascota,
mas.sexo as sexo_mascota,
tc.id as key_tipo_cita,
es.id as key_estado,
ct.fecha_inicio,
ct.hora_inicio,
ct.hora_fin,
ct.motivo_consulta,
ct.observacion_sistema,
ct.diagnostico,
ct.recomendacion,
CONCAT(vt.nombre, ' ' , vt.apellido) as nombre_completo_veterinario,
vt.dni as dni_vt,
vt.num_cel as num_cel_vt,
vt.correo as correo_vt,
cl.dni as dni_cl,
cl.correo,
CONCAT(cl.nombre, ' ' , cl.apellido) as nombre_completo_cliente,
cl.num_cel,
mas.nombre as nombre_mascota,
rz.nombre_raza,
tm.tipo as especie,
ser.nombre_servicio,
ser.precio,
ser.duracion,
tc.tipo_cita,
ts.id as key_tipo_servicio,
ts.tipo_servicio,
es.nombre as estado,
es.color,
es.icon,
CONCAT(
extract(year from age(NOW(), mas.fecha_nacimiento::date)), ' años ',
extract(month  from age(NOW(), mas.fecha_nacimiento::date)), ' meses '
) as edad
FROM cita ct
LEFT JOIN veterinario vt on vt.id = ct.key_veterinario_id
LEFT JOIN cliente cl on cl.id = ct.key_cliente_id
LEFT JOIN mascota mas on mas.id = ct.key_mascota_id
LEFT JOIN raza rz on rz.id = mas.key_raza_id
LEFT JOIN tipo_mascota tm on tm.id = mas.key_tipo_mascota_id
LEFT JOIN servicio ser on ser.id = ct.key_servicio_id
LEFT JOIN tipo_cita tc on tc.id = ct.key_tipo_cita_id
LEFT JOIN tipo_servicio ts on ts.id = ser.key_tipo_servicio_id
LEFT JOIN estado es on es.id = ct.key_estado_id
WHERE 
CASE WHEN pid = 0 THEN
	ct.id = ct.id
else 
	ct.id =  pid
end;
end;
$$;


ALTER FUNCTION public.fn_listar_cita(pid integer) OWNER TO "djBackends";

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 276 (class 1259 OID 17014)
-- Name: detalle_receta; Type: TABLE; Schema: public; Owner: djBackends
--

CREATE TABLE public.detalle_receta (
    id bigint NOT NULL,
    tratamiento text,
    key_medicamento_id bigint,
    key_receta_id bigint
);


ALTER TABLE public.detalle_receta OWNER TO "djBackends";

--
-- TOC entry 275 (class 1259 OID 17013)
-- Name: app_veterinaria_detalle_receta_id_seq; Type: SEQUENCE; Schema: public; Owner: djBackends
--

CREATE SEQUENCE public.app_veterinaria_detalle_receta_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.app_veterinaria_detalle_receta_id_seq OWNER TO "djBackends";

--
-- TOC entry 3784 (class 0 OID 0)
-- Dependencies: 275
-- Name: app_veterinaria_detalle_receta_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: djBackends
--

ALTER SEQUENCE public.app_veterinaria_detalle_receta_id_seq OWNED BY public.detalle_receta.id;


--
-- TOC entry 268 (class 1259 OID 16942)
-- Name: permiso; Type: TABLE; Schema: public; Owner: djBackends
--

CREATE TABLE public.permiso (
    id bigint NOT NULL,
    permiso text,
    fecha_registro timestamp with time zone NOT NULL,
    key_estado_id bigint
);


ALTER TABLE public.permiso OWNER TO "djBackends";

--
-- TOC entry 267 (class 1259 OID 16941)
-- Name: app_veterinaria_permiso_id_seq; Type: SEQUENCE; Schema: public; Owner: djBackends
--

CREATE SEQUENCE public.app_veterinaria_permiso_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.app_veterinaria_permiso_id_seq OWNER TO "djBackends";

--
-- TOC entry 3785 (class 0 OID 0)
-- Dependencies: 267
-- Name: app_veterinaria_permiso_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: djBackends
--

ALTER SEQUENCE public.app_veterinaria_permiso_id_seq OWNED BY public.permiso.id;


--
-- TOC entry 260 (class 1259 OID 16803)
-- Name: asignacion_permiso; Type: TABLE; Schema: public; Owner: djBackends
--

CREATE TABLE public.asignacion_permiso (
    id bigint NOT NULL,
    key_menu_id bigint,
    key_tipo_usuario_id bigint,
    key_permiso_id bigint
);


ALTER TABLE public.asignacion_permiso OWNER TO "djBackends";

--
-- TOC entry 259 (class 1259 OID 16802)
-- Name: asignacion_permiso_id_seq; Type: SEQUENCE; Schema: public; Owner: djBackends
--

CREATE SEQUENCE public.asignacion_permiso_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.asignacion_permiso_id_seq OWNER TO "djBackends";

--
-- TOC entry 3786 (class 0 OID 0)
-- Dependencies: 259
-- Name: asignacion_permiso_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: djBackends
--

ALTER SEQUENCE public.asignacion_permiso_id_seq OWNED BY public.asignacion_permiso.id;


--
-- TOC entry 246 (class 1259 OID 16647)
-- Name: auth_group; Type: TABLE; Schema: public; Owner: djBackends
--

CREATE TABLE public.auth_group (
    id integer NOT NULL,
    name character varying(150) NOT NULL
);


ALTER TABLE public.auth_group OWNER TO "djBackends";

--
-- TOC entry 245 (class 1259 OID 16646)
-- Name: auth_group_id_seq; Type: SEQUENCE; Schema: public; Owner: djBackends
--

CREATE SEQUENCE public.auth_group_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.auth_group_id_seq OWNER TO "djBackends";

--
-- TOC entry 3787 (class 0 OID 0)
-- Dependencies: 245
-- Name: auth_group_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: djBackends
--

ALTER SEQUENCE public.auth_group_id_seq OWNED BY public.auth_group.id;


--
-- TOC entry 248 (class 1259 OID 16656)
-- Name: auth_group_permissions; Type: TABLE; Schema: public; Owner: djBackends
--

CREATE TABLE public.auth_group_permissions (
    id bigint NOT NULL,
    group_id integer NOT NULL,
    permission_id integer NOT NULL
);


ALTER TABLE public.auth_group_permissions OWNER TO "djBackends";

--
-- TOC entry 247 (class 1259 OID 16655)
-- Name: auth_group_permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: djBackends
--

CREATE SEQUENCE public.auth_group_permissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.auth_group_permissions_id_seq OWNER TO "djBackends";

--
-- TOC entry 3788 (class 0 OID 0)
-- Dependencies: 247
-- Name: auth_group_permissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: djBackends
--

ALTER SEQUENCE public.auth_group_permissions_id_seq OWNED BY public.auth_group_permissions.id;


--
-- TOC entry 244 (class 1259 OID 16640)
-- Name: auth_permission; Type: TABLE; Schema: public; Owner: djBackends
--

CREATE TABLE public.auth_permission (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    content_type_id integer NOT NULL,
    codename character varying(100) NOT NULL
);


ALTER TABLE public.auth_permission OWNER TO "djBackends";

--
-- TOC entry 243 (class 1259 OID 16639)
-- Name: auth_permission_id_seq; Type: SEQUENCE; Schema: public; Owner: djBackends
--

CREATE SEQUENCE public.auth_permission_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.auth_permission_id_seq OWNER TO "djBackends";

--
-- TOC entry 3789 (class 0 OID 0)
-- Dependencies: 243
-- Name: auth_permission_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: djBackends
--

ALTER SEQUENCE public.auth_permission_id_seq OWNED BY public.auth_permission.id;


--
-- TOC entry 240 (class 1259 OID 16525)
-- Name: cita; Type: TABLE; Schema: public; Owner: djBackends
--

CREATE TABLE public.cita (
    id bigint NOT NULL,
    fecha_registro timestamp with time zone NOT NULL,
    key_cliente_id bigint,
    key_estado_id bigint,
    key_mascota_id bigint,
    key_veterinario_id bigint,
    key_tipo_cita_id bigint,
    fecha_inicio date,
    hora_fin text,
    hora_inicio text,
    motivo_consulta text,
    key_servicio_id bigint,
    motivo_cancelacion text,
    diagnostico text,
    observacion_sistema text,
    recomendacion text,
    tiempo_estimado text
);


ALTER TABLE public.cita OWNER TO "djBackends";

--
-- TOC entry 239 (class 1259 OID 16524)
-- Name: cita_id_seq; Type: SEQUENCE; Schema: public; Owner: djBackends
--

CREATE SEQUENCE public.cita_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cita_id_seq OWNER TO "djBackends";

--
-- TOC entry 3790 (class 0 OID 0)
-- Dependencies: 239
-- Name: cita_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: djBackends
--

ALTER SEQUENCE public.cita_id_seq OWNED BY public.cita.id;


--
-- TOC entry 220 (class 1259 OID 16407)
-- Name: cliente; Type: TABLE; Schema: public; Owner: djBackends
--

CREATE TABLE public.cliente (
    id bigint NOT NULL,
    dni text,
    nombre text,
    apellido text,
    direccion text,
    num_cel text,
    correo text,
    fecha_registro timestamp with time zone NOT NULL,
    key_estado_id bigint,
    sexo text
);


ALTER TABLE public.cliente OWNER TO "djBackends";

--
-- TOC entry 219 (class 1259 OID 16406)
-- Name: cliente_id_seq; Type: SEQUENCE; Schema: public; Owner: djBackends
--

CREATE SEQUENCE public.cliente_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cliente_id_seq OWNER TO "djBackends";

--
-- TOC entry 3791 (class 0 OID 0)
-- Dependencies: 219
-- Name: cliente_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: djBackends
--

ALTER SEQUENCE public.cliente_id_seq OWNED BY public.cliente.id;


--
-- TOC entry 242 (class 1259 OID 16618)
-- Name: django_admin_log; Type: TABLE; Schema: public; Owner: djBackends
--

CREATE TABLE public.django_admin_log (
    id integer NOT NULL,
    action_time timestamp with time zone NOT NULL,
    object_id text,
    object_repr character varying(200) NOT NULL,
    action_flag smallint NOT NULL,
    change_message text NOT NULL,
    content_type_id integer,
    user_id bigint NOT NULL,
    CONSTRAINT django_admin_log_action_flag_check CHECK ((action_flag >= 0))
);


ALTER TABLE public.django_admin_log OWNER TO "djBackends";

--
-- TOC entry 241 (class 1259 OID 16617)
-- Name: django_admin_log_id_seq; Type: SEQUENCE; Schema: public; Owner: djBackends
--

CREATE SEQUENCE public.django_admin_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.django_admin_log_id_seq OWNER TO "djBackends";

--
-- TOC entry 3792 (class 0 OID 0)
-- Dependencies: 241
-- Name: django_admin_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: djBackends
--

ALTER SEQUENCE public.django_admin_log_id_seq OWNED BY public.django_admin_log.id;


--
-- TOC entry 218 (class 1259 OID 16398)
-- Name: django_content_type; Type: TABLE; Schema: public; Owner: djBackends
--

CREATE TABLE public.django_content_type (
    id integer NOT NULL,
    app_label character varying(100) NOT NULL,
    model character varying(100) NOT NULL
);


ALTER TABLE public.django_content_type OWNER TO "djBackends";

--
-- TOC entry 217 (class 1259 OID 16397)
-- Name: django_content_type_id_seq; Type: SEQUENCE; Schema: public; Owner: djBackends
--

CREATE SEQUENCE public.django_content_type_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.django_content_type_id_seq OWNER TO "djBackends";

--
-- TOC entry 3793 (class 0 OID 0)
-- Dependencies: 217
-- Name: django_content_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: djBackends
--

ALTER SEQUENCE public.django_content_type_id_seq OWNED BY public.django_content_type.id;


--
-- TOC entry 216 (class 1259 OID 16389)
-- Name: django_migrations; Type: TABLE; Schema: public; Owner: djBackends
--

CREATE TABLE public.django_migrations (
    id bigint NOT NULL,
    app character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    applied timestamp with time zone NOT NULL
);


ALTER TABLE public.django_migrations OWNER TO "djBackends";

--
-- TOC entry 215 (class 1259 OID 16388)
-- Name: django_migrations_id_seq; Type: SEQUENCE; Schema: public; Owner: djBackends
--

CREATE SEQUENCE public.django_migrations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.django_migrations_id_seq OWNER TO "djBackends";

--
-- TOC entry 3794 (class 0 OID 0)
-- Dependencies: 215
-- Name: django_migrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: djBackends
--

ALTER SEQUENCE public.django_migrations_id_seq OWNED BY public.django_migrations.id;


--
-- TOC entry 277 (class 1259 OID 17034)
-- Name: django_session; Type: TABLE; Schema: public; Owner: djBackends
--

CREATE TABLE public.django_session (
    session_key character varying(40) NOT NULL,
    session_data text NOT NULL,
    expire_date timestamp with time zone NOT NULL
);


ALTER TABLE public.django_session OWNER TO "djBackends";

--
-- TOC entry 222 (class 1259 OID 16416)
-- Name: estado; Type: TABLE; Schema: public; Owner: djBackends
--

CREATE TABLE public.estado (
    id bigint NOT NULL,
    nombre text,
    abreviatura text,
    descripcion text,
    accion text,
    color text,
    icon text,
    key_tipo_estado_id bigint NOT NULL
);


ALTER TABLE public.estado OWNER TO "djBackends";

--
-- TOC entry 221 (class 1259 OID 16415)
-- Name: estado_id_seq; Type: SEQUENCE; Schema: public; Owner: djBackends
--

CREATE SEQUENCE public.estado_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.estado_id_seq OWNER TO "djBackends";

--
-- TOC entry 3795 (class 0 OID 0)
-- Dependencies: 221
-- Name: estado_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: djBackends
--

ALTER SEQUENCE public.estado_id_seq OWNED BY public.estado.id;


--
-- TOC entry 224 (class 1259 OID 16425)
-- Name: evento; Type: TABLE; Schema: public; Owner: djBackends
--

CREATE TABLE public.evento (
    id bigint NOT NULL,
    nombre text,
    color text,
    icon text
);


ALTER TABLE public.evento OWNER TO "djBackends";

--
-- TOC entry 223 (class 1259 OID 16424)
-- Name: evento_id_seq; Type: SEQUENCE; Schema: public; Owner: djBackends
--

CREATE SEQUENCE public.evento_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.evento_id_seq OWNER TO "djBackends";

--
-- TOC entry 3796 (class 0 OID 0)
-- Dependencies: 223
-- Name: evento_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: djBackends
--

ALTER SEQUENCE public.evento_id_seq OWNED BY public.evento.id;


--
-- TOC entry 238 (class 1259 OID 16506)
-- Name: log; Type: TABLE; Schema: public; Owner: djBackends
--

CREATE TABLE public.log (
    id bigint NOT NULL,
    nombre_tabla text,
    key_tabla integer NOT NULL,
    fecha_hora_registro timestamp with time zone NOT NULL,
    descripcion text,
    key_evento_id bigint NOT NULL,
    key_usuario_id bigint
);


ALTER TABLE public.log OWNER TO "djBackends";

--
-- TOC entry 237 (class 1259 OID 16505)
-- Name: log_id_seq; Type: SEQUENCE; Schema: public; Owner: djBackends
--

CREATE SEQUENCE public.log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.log_id_seq OWNER TO "djBackends";

--
-- TOC entry 3797 (class 0 OID 0)
-- Dependencies: 237
-- Name: log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: djBackends
--

ALTER SEQUENCE public.log_id_seq OWNED BY public.log.id;


--
-- TOC entry 236 (class 1259 OID 16497)
-- Name: mascota; Type: TABLE; Schema: public; Owner: djBackends
--

CREATE TABLE public.mascota (
    id bigint NOT NULL,
    nombre text,
    fecha_nacimiento text,
    sexo text,
    color text,
    fecha_registro timestamp with time zone NOT NULL,
    key_cliente_id bigint,
    key_estado_id bigint,
    key_raza_id bigint,
    key_tipo_mascota_id bigint
);


ALTER TABLE public.mascota OWNER TO "djBackends";

--
-- TOC entry 235 (class 1259 OID 16496)
-- Name: mascota_id_seq; Type: SEQUENCE; Schema: public; Owner: djBackends
--

CREATE SEQUENCE public.mascota_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.mascota_id_seq OWNER TO "djBackends";

--
-- TOC entry 3798 (class 0 OID 0)
-- Dependencies: 235
-- Name: mascota_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: djBackends
--

ALTER SEQUENCE public.mascota_id_seq OWNED BY public.mascota.id;


--
-- TOC entry 270 (class 1259 OID 16963)
-- Name: medicina; Type: TABLE; Schema: public; Owner: djBackends
--

CREATE TABLE public.medicina (
    id bigint NOT NULL,
    codigo text,
    nombre text,
    descripcion text,
    key_estado_id bigint
);


ALTER TABLE public.medicina OWNER TO "djBackends";

--
-- TOC entry 269 (class 1259 OID 16962)
-- Name: medicina_id_seq; Type: SEQUENCE; Schema: public; Owner: djBackends
--

CREATE SEQUENCE public.medicina_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.medicina_id_seq OWNER TO "djBackends";

--
-- TOC entry 3799 (class 0 OID 0)
-- Dependencies: 269
-- Name: medicina_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: djBackends
--

ALTER SEQUENCE public.medicina_id_seq OWNED BY public.medicina.id;


--
-- TOC entry 258 (class 1259 OID 16794)
-- Name: menu; Type: TABLE; Schema: public; Owner: djBackends
--

CREATE TABLE public.menu (
    id bigint NOT NULL,
    menu text,
    descripcion text
);


ALTER TABLE public.menu OWNER TO "djBackends";

--
-- TOC entry 257 (class 1259 OID 16793)
-- Name: menu_id_seq; Type: SEQUENCE; Schema: public; Owner: djBackends
--

CREATE SEQUENCE public.menu_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.menu_id_seq OWNER TO "djBackends";

--
-- TOC entry 3800 (class 0 OID 0)
-- Dependencies: 257
-- Name: menu_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: djBackends
--

ALTER SEQUENCE public.menu_id_seq OWNED BY public.menu.id;


--
-- TOC entry 256 (class 1259 OID 16779)
-- Name: pregunta_frecuente; Type: TABLE; Schema: public; Owner: djBackends
--

CREATE TABLE public.pregunta_frecuente (
    id bigint NOT NULL,
    asunto text,
    descripcion text,
    key_estado_id bigint
);


ALTER TABLE public.pregunta_frecuente OWNER TO "djBackends";

--
-- TOC entry 255 (class 1259 OID 16778)
-- Name: pregunta_frecuente_id_seq; Type: SEQUENCE; Schema: public; Owner: djBackends
--

CREATE SEQUENCE public.pregunta_frecuente_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pregunta_frecuente_id_seq OWNER TO "djBackends";

--
-- TOC entry 3801 (class 0 OID 0)
-- Dependencies: 255
-- Name: pregunta_frecuente_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: djBackends
--

ALTER SEQUENCE public.pregunta_frecuente_id_seq OWNED BY public.pregunta_frecuente.id;


--
-- TOC entry 226 (class 1259 OID 16434)
-- Name: raza; Type: TABLE; Schema: public; Owner: djBackends
--

CREATE TABLE public.raza (
    id bigint NOT NULL,
    nombre_raza text,
    descripcion text,
    key_estado_id bigint
);


ALTER TABLE public.raza OWNER TO "djBackends";

--
-- TOC entry 225 (class 1259 OID 16433)
-- Name: raza_id_seq; Type: SEQUENCE; Schema: public; Owner: djBackends
--

CREATE SEQUENCE public.raza_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.raza_id_seq OWNER TO "djBackends";

--
-- TOC entry 3802 (class 0 OID 0)
-- Dependencies: 225
-- Name: raza_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: djBackends
--

ALTER SEQUENCE public.raza_id_seq OWNED BY public.raza.id;


--
-- TOC entry 274 (class 1259 OID 16981)
-- Name: receta; Type: TABLE; Schema: public; Owner: djBackends
--

CREATE TABLE public.receta (
    id bigint NOT NULL,
    fecha_creacion timestamp with time zone NOT NULL,
    key_cita_id bigint
);


ALTER TABLE public.receta OWNER TO "djBackends";

--
-- TOC entry 273 (class 1259 OID 16980)
-- Name: receta_id_seq; Type: SEQUENCE; Schema: public; Owner: djBackends
--

CREATE SEQUENCE public.receta_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.receta_id_seq OWNER TO "djBackends";

--
-- TOC entry 3803 (class 0 OID 0)
-- Dependencies: 273
-- Name: receta_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: djBackends
--

ALTER SEQUENCE public.receta_id_seq OWNED BY public.receta.id;


--
-- TOC entry 279 (class 1259 OID 49154)
-- Name: restablecer_usuario; Type: TABLE; Schema: public; Owner: djBackends
--

CREATE TABLE public.restablecer_usuario (
    id bigint NOT NULL,
    toke text,
    fecha_creacion timestamp with time zone NOT NULL,
    expired timestamp with time zone NOT NULL,
    codigo_recuperacion text NOT NULL,
    is_activo boolean NOT NULL,
    key_usuario_id bigint
);


ALTER TABLE public.restablecer_usuario OWNER TO "djBackends";

--
-- TOC entry 278 (class 1259 OID 49153)
-- Name: restablecer_usuario_id_seq; Type: SEQUENCE; Schema: public; Owner: djBackends
--

CREATE SEQUENCE public.restablecer_usuario_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.restablecer_usuario_id_seq OWNER TO "djBackends";

--
-- TOC entry 3804 (class 0 OID 0)
-- Dependencies: 278
-- Name: restablecer_usuario_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: djBackends
--

ALTER SEQUENCE public.restablecer_usuario_id_seq OWNED BY public.restablecer_usuario.id;


--
-- TOC entry 228 (class 1259 OID 16443)
-- Name: servicio; Type: TABLE; Schema: public; Owner: djBackends
--

CREATE TABLE public.servicio (
    id bigint NOT NULL,
    nombre_servicio text,
    descripcion text,
    precio double precision,
    key_estado_id bigint,
    key_tipo_servicio_id bigint,
    duracion text
);


ALTER TABLE public.servicio OWNER TO "djBackends";

--
-- TOC entry 227 (class 1259 OID 16442)
-- Name: servicio_id_seq; Type: SEQUENCE; Schema: public; Owner: djBackends
--

CREATE SEQUENCE public.servicio_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.servicio_id_seq OWNER TO "djBackends";

--
-- TOC entry 3805 (class 0 OID 0)
-- Dependencies: 227
-- Name: servicio_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: djBackends
--

ALTER SEQUENCE public.servicio_id_seq OWNED BY public.servicio.id;


--
-- TOC entry 254 (class 1259 OID 16750)
-- Name: tipo_cita; Type: TABLE; Schema: public; Owner: djBackends
--

CREATE TABLE public.tipo_cita (
    id bigint NOT NULL,
    tipo_cita text,
    descripcion text,
    key_estado_id bigint
);


ALTER TABLE public.tipo_cita OWNER TO "djBackends";

--
-- TOC entry 253 (class 1259 OID 16749)
-- Name: tipo_cita_id_seq; Type: SEQUENCE; Schema: public; Owner: djBackends
--

CREATE SEQUENCE public.tipo_cita_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tipo_cita_id_seq OWNER TO "djBackends";

--
-- TOC entry 3806 (class 0 OID 0)
-- Dependencies: 253
-- Name: tipo_cita_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: djBackends
--

ALTER SEQUENCE public.tipo_cita_id_seq OWNED BY public.tipo_cita.id;


--
-- TOC entry 230 (class 1259 OID 16452)
-- Name: tipo_estado; Type: TABLE; Schema: public; Owner: djBackends
--

CREATE TABLE public.tipo_estado (
    id bigint NOT NULL,
    nombre text,
    descripcion text
);


ALTER TABLE public.tipo_estado OWNER TO "djBackends";

--
-- TOC entry 229 (class 1259 OID 16451)
-- Name: tipo_estado_id_seq; Type: SEQUENCE; Schema: public; Owner: djBackends
--

CREATE SEQUENCE public.tipo_estado_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tipo_estado_id_seq OWNER TO "djBackends";

--
-- TOC entry 3807 (class 0 OID 0)
-- Dependencies: 229
-- Name: tipo_estado_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: djBackends
--

ALTER SEQUENCE public.tipo_estado_id_seq OWNED BY public.tipo_estado.id;


--
-- TOC entry 252 (class 1259 OID 16729)
-- Name: tipo_mascota; Type: TABLE; Schema: public; Owner: djBackends
--

CREATE TABLE public.tipo_mascota (
    id bigint NOT NULL,
    tipo text,
    descripcion text,
    key_estado_id bigint
);


ALTER TABLE public.tipo_mascota OWNER TO "djBackends";

--
-- TOC entry 251 (class 1259 OID 16728)
-- Name: tipo_mascota_id_seq; Type: SEQUENCE; Schema: public; Owner: djBackends
--

CREATE SEQUENCE public.tipo_mascota_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tipo_mascota_id_seq OWNER TO "djBackends";

--
-- TOC entry 3808 (class 0 OID 0)
-- Dependencies: 251
-- Name: tipo_mascota_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: djBackends
--

ALTER SEQUENCE public.tipo_mascota_id_seq OWNED BY public.tipo_mascota.id;


--
-- TOC entry 250 (class 1259 OID 16695)
-- Name: tipo_servicio; Type: TABLE; Schema: public; Owner: djBackends
--

CREATE TABLE public.tipo_servicio (
    id bigint NOT NULL,
    tipo_servicio text,
    descripcion text,
    key_estado_id bigint
);


ALTER TABLE public.tipo_servicio OWNER TO "djBackends";

--
-- TOC entry 249 (class 1259 OID 16694)
-- Name: tipo_servicio_id_seq; Type: SEQUENCE; Schema: public; Owner: djBackends
--

CREATE SEQUENCE public.tipo_servicio_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tipo_servicio_id_seq OWNER TO "djBackends";

--
-- TOC entry 3809 (class 0 OID 0)
-- Dependencies: 249
-- Name: tipo_servicio_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: djBackends
--

ALTER SEQUENCE public.tipo_servicio_id_seq OWNED BY public.tipo_servicio.id;


--
-- TOC entry 232 (class 1259 OID 16461)
-- Name: tipo_usuario; Type: TABLE; Schema: public; Owner: djBackends
--

CREATE TABLE public.tipo_usuario (
    id bigint NOT NULL,
    tipo_usuario text,
    descripcion text,
    action text
);


ALTER TABLE public.tipo_usuario OWNER TO "djBackends";

--
-- TOC entry 231 (class 1259 OID 16460)
-- Name: tipo_usuario_id_seq; Type: SEQUENCE; Schema: public; Owner: djBackends
--

CREATE SEQUENCE public.tipo_usuario_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tipo_usuario_id_seq OWNER TO "djBackends";

--
-- TOC entry 3810 (class 0 OID 0)
-- Dependencies: 231
-- Name: tipo_usuario_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: djBackends
--

ALTER SEQUENCE public.tipo_usuario_id_seq OWNED BY public.tipo_usuario.id;


--
-- TOC entry 272 (class 1259 OID 16972)
-- Name: triaje; Type: TABLE; Schema: public; Owner: djBackends
--

CREATE TABLE public.triaje (
    id bigint NOT NULL,
    peso text,
    temperatura text,
    frecuencia_cardica text,
    frecuencia_respiratoria text,
    key_cita_id bigint
);


ALTER TABLE public.triaje OWNER TO "djBackends";

--
-- TOC entry 271 (class 1259 OID 16971)
-- Name: triaje_id_seq; Type: SEQUENCE; Schema: public; Owner: djBackends
--

CREATE SEQUENCE public.triaje_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.triaje_id_seq OWNER TO "djBackends";

--
-- TOC entry 3811 (class 0 OID 0)
-- Dependencies: 271
-- Name: triaje_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: djBackends
--

ALTER SEQUENCE public.triaje_id_seq OWNED BY public.triaje.id;


--
-- TOC entry 262 (class 1259 OID 16840)
-- Name: usuario; Type: TABLE; Schema: public; Owner: djBackends
--

CREATE TABLE public.usuario (
    id bigint NOT NULL,
    password character varying(128) NOT NULL,
    last_login timestamp with time zone NOT NULL,
    is_superuser boolean NOT NULL,
    username character varying(150) NOT NULL,
    first_name character varying(150) NOT NULL,
    last_name character varying(150) NOT NULL,
    email character varying(254) NOT NULL,
    is_staff boolean NOT NULL,
    is_active boolean NOT NULL,
    date_joined timestamp with time zone NOT NULL,
    document_number text NOT NULL,
    user_type_id bigint,
    status_id bigint
);


ALTER TABLE public.usuario OWNER TO "djBackends";

--
-- TOC entry 264 (class 1259 OID 16853)
-- Name: usuario_groups; Type: TABLE; Schema: public; Owner: djBackends
--

CREATE TABLE public.usuario_groups (
    id bigint NOT NULL,
    usuario_id bigint NOT NULL,
    group_id integer NOT NULL
);


ALTER TABLE public.usuario_groups OWNER TO "djBackends";

--
-- TOC entry 263 (class 1259 OID 16852)
-- Name: usuario_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: djBackends
--

CREATE SEQUENCE public.usuario_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.usuario_groups_id_seq OWNER TO "djBackends";

--
-- TOC entry 3812 (class 0 OID 0)
-- Dependencies: 263
-- Name: usuario_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: djBackends
--

ALTER SEQUENCE public.usuario_groups_id_seq OWNED BY public.usuario_groups.id;


--
-- TOC entry 261 (class 1259 OID 16839)
-- Name: usuario_id_seq; Type: SEQUENCE; Schema: public; Owner: djBackends
--

CREATE SEQUENCE public.usuario_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.usuario_id_seq OWNER TO "djBackends";

--
-- TOC entry 3813 (class 0 OID 0)
-- Dependencies: 261
-- Name: usuario_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: djBackends
--

ALTER SEQUENCE public.usuario_id_seq OWNED BY public.usuario.id;


--
-- TOC entry 266 (class 1259 OID 16867)
-- Name: usuario_user_permissions; Type: TABLE; Schema: public; Owner: djBackends
--

CREATE TABLE public.usuario_user_permissions (
    id bigint NOT NULL,
    usuario_id bigint NOT NULL,
    permission_id integer NOT NULL
);


ALTER TABLE public.usuario_user_permissions OWNER TO "djBackends";

--
-- TOC entry 265 (class 1259 OID 16866)
-- Name: usuario_user_permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: djBackends
--

CREATE SEQUENCE public.usuario_user_permissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.usuario_user_permissions_id_seq OWNER TO "djBackends";

--
-- TOC entry 3814 (class 0 OID 0)
-- Dependencies: 265
-- Name: usuario_user_permissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: djBackends
--

ALTER SEQUENCE public.usuario_user_permissions_id_seq OWNED BY public.usuario_user_permissions.id;


--
-- TOC entry 234 (class 1259 OID 16470)
-- Name: veterinario; Type: TABLE; Schema: public; Owner: djBackends
--

CREATE TABLE public.veterinario (
    id bigint NOT NULL,
    nombre text,
    apellido text,
    direccion text,
    correo text,
    fecha_registro timestamp with time zone NOT NULL,
    num_cel text,
    key_estado_id bigint,
    dni text,
    sexo text
);


ALTER TABLE public.veterinario OWNER TO "djBackends";

--
-- TOC entry 233 (class 1259 OID 16469)
-- Name: veterinario_id_seq; Type: SEQUENCE; Schema: public; Owner: djBackends
--

CREATE SEQUENCE public.veterinario_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.veterinario_id_seq OWNER TO "djBackends";

--
-- TOC entry 3815 (class 0 OID 0)
-- Dependencies: 233
-- Name: veterinario_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: djBackends
--

ALTER SEQUENCE public.veterinario_id_seq OWNED BY public.veterinario.id;


--
-- TOC entry 3388 (class 2604 OID 16806)
-- Name: asignacion_permiso id; Type: DEFAULT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.asignacion_permiso ALTER COLUMN id SET DEFAULT nextval('public.asignacion_permiso_id_seq'::regclass);


--
-- TOC entry 3381 (class 2604 OID 16650)
-- Name: auth_group id; Type: DEFAULT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.auth_group ALTER COLUMN id SET DEFAULT nextval('public.auth_group_id_seq'::regclass);


--
-- TOC entry 3382 (class 2604 OID 16659)
-- Name: auth_group_permissions id; Type: DEFAULT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.auth_group_permissions ALTER COLUMN id SET DEFAULT nextval('public.auth_group_permissions_id_seq'::regclass);


--
-- TOC entry 3380 (class 2604 OID 16643)
-- Name: auth_permission id; Type: DEFAULT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.auth_permission ALTER COLUMN id SET DEFAULT nextval('public.auth_permission_id_seq'::regclass);


--
-- TOC entry 3378 (class 2604 OID 16528)
-- Name: cita id; Type: DEFAULT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.cita ALTER COLUMN id SET DEFAULT nextval('public.cita_id_seq'::regclass);


--
-- TOC entry 3368 (class 2604 OID 16410)
-- Name: cliente id; Type: DEFAULT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.cliente ALTER COLUMN id SET DEFAULT nextval('public.cliente_id_seq'::regclass);


--
-- TOC entry 3396 (class 2604 OID 17017)
-- Name: detalle_receta id; Type: DEFAULT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.detalle_receta ALTER COLUMN id SET DEFAULT nextval('public.app_veterinaria_detalle_receta_id_seq'::regclass);


--
-- TOC entry 3379 (class 2604 OID 16621)
-- Name: django_admin_log id; Type: DEFAULT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.django_admin_log ALTER COLUMN id SET DEFAULT nextval('public.django_admin_log_id_seq'::regclass);


--
-- TOC entry 3367 (class 2604 OID 16401)
-- Name: django_content_type id; Type: DEFAULT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.django_content_type ALTER COLUMN id SET DEFAULT nextval('public.django_content_type_id_seq'::regclass);


--
-- TOC entry 3366 (class 2604 OID 16392)
-- Name: django_migrations id; Type: DEFAULT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.django_migrations ALTER COLUMN id SET DEFAULT nextval('public.django_migrations_id_seq'::regclass);


--
-- TOC entry 3369 (class 2604 OID 16419)
-- Name: estado id; Type: DEFAULT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.estado ALTER COLUMN id SET DEFAULT nextval('public.estado_id_seq'::regclass);


--
-- TOC entry 3370 (class 2604 OID 16428)
-- Name: evento id; Type: DEFAULT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.evento ALTER COLUMN id SET DEFAULT nextval('public.evento_id_seq'::regclass);


--
-- TOC entry 3377 (class 2604 OID 16509)
-- Name: log id; Type: DEFAULT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.log ALTER COLUMN id SET DEFAULT nextval('public.log_id_seq'::regclass);


--
-- TOC entry 3376 (class 2604 OID 16500)
-- Name: mascota id; Type: DEFAULT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.mascota ALTER COLUMN id SET DEFAULT nextval('public.mascota_id_seq'::regclass);


--
-- TOC entry 3393 (class 2604 OID 16966)
-- Name: medicina id; Type: DEFAULT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.medicina ALTER COLUMN id SET DEFAULT nextval('public.medicina_id_seq'::regclass);


--
-- TOC entry 3387 (class 2604 OID 16797)
-- Name: menu id; Type: DEFAULT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.menu ALTER COLUMN id SET DEFAULT nextval('public.menu_id_seq'::regclass);


--
-- TOC entry 3392 (class 2604 OID 16945)
-- Name: permiso id; Type: DEFAULT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.permiso ALTER COLUMN id SET DEFAULT nextval('public.app_veterinaria_permiso_id_seq'::regclass);


--
-- TOC entry 3386 (class 2604 OID 16782)
-- Name: pregunta_frecuente id; Type: DEFAULT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.pregunta_frecuente ALTER COLUMN id SET DEFAULT nextval('public.pregunta_frecuente_id_seq'::regclass);


--
-- TOC entry 3371 (class 2604 OID 16437)
-- Name: raza id; Type: DEFAULT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.raza ALTER COLUMN id SET DEFAULT nextval('public.raza_id_seq'::regclass);


--
-- TOC entry 3395 (class 2604 OID 16984)
-- Name: receta id; Type: DEFAULT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.receta ALTER COLUMN id SET DEFAULT nextval('public.receta_id_seq'::regclass);


--
-- TOC entry 3397 (class 2604 OID 49157)
-- Name: restablecer_usuario id; Type: DEFAULT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.restablecer_usuario ALTER COLUMN id SET DEFAULT nextval('public.restablecer_usuario_id_seq'::regclass);


--
-- TOC entry 3372 (class 2604 OID 16446)
-- Name: servicio id; Type: DEFAULT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.servicio ALTER COLUMN id SET DEFAULT nextval('public.servicio_id_seq'::regclass);


--
-- TOC entry 3385 (class 2604 OID 16753)
-- Name: tipo_cita id; Type: DEFAULT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.tipo_cita ALTER COLUMN id SET DEFAULT nextval('public.tipo_cita_id_seq'::regclass);


--
-- TOC entry 3373 (class 2604 OID 16455)
-- Name: tipo_estado id; Type: DEFAULT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.tipo_estado ALTER COLUMN id SET DEFAULT nextval('public.tipo_estado_id_seq'::regclass);


--
-- TOC entry 3384 (class 2604 OID 16732)
-- Name: tipo_mascota id; Type: DEFAULT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.tipo_mascota ALTER COLUMN id SET DEFAULT nextval('public.tipo_mascota_id_seq'::regclass);


--
-- TOC entry 3383 (class 2604 OID 16698)
-- Name: tipo_servicio id; Type: DEFAULT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.tipo_servicio ALTER COLUMN id SET DEFAULT nextval('public.tipo_servicio_id_seq'::regclass);


--
-- TOC entry 3374 (class 2604 OID 16464)
-- Name: tipo_usuario id; Type: DEFAULT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.tipo_usuario ALTER COLUMN id SET DEFAULT nextval('public.tipo_usuario_id_seq'::regclass);


--
-- TOC entry 3394 (class 2604 OID 16975)
-- Name: triaje id; Type: DEFAULT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.triaje ALTER COLUMN id SET DEFAULT nextval('public.triaje_id_seq'::regclass);


--
-- TOC entry 3389 (class 2604 OID 16843)
-- Name: usuario id; Type: DEFAULT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.usuario ALTER COLUMN id SET DEFAULT nextval('public.usuario_id_seq'::regclass);


--
-- TOC entry 3390 (class 2604 OID 16856)
-- Name: usuario_groups id; Type: DEFAULT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.usuario_groups ALTER COLUMN id SET DEFAULT nextval('public.usuario_groups_id_seq'::regclass);


--
-- TOC entry 3391 (class 2604 OID 16870)
-- Name: usuario_user_permissions id; Type: DEFAULT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.usuario_user_permissions ALTER COLUMN id SET DEFAULT nextval('public.usuario_user_permissions_id_seq'::regclass);


--
-- TOC entry 3375 (class 2604 OID 16473)
-- Name: veterinario id; Type: DEFAULT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.veterinario ALTER COLUMN id SET DEFAULT nextval('public.veterinario_id_seq'::regclass);


--
-- TOC entry 3759 (class 0 OID 16803)
-- Dependencies: 260
-- Data for Name: asignacion_permiso; Type: TABLE DATA; Schema: public; Owner: djBackends
--

COPY public.asignacion_permiso (id, key_menu_id, key_tipo_usuario_id, key_permiso_id) FROM stdin;
1	11	1	2
2	1	2	5
4	1	3	5
3	8	2	5
5	8	3	5
\.


--
-- TOC entry 3745 (class 0 OID 16647)
-- Dependencies: 246
-- Data for Name: auth_group; Type: TABLE DATA; Schema: public; Owner: djBackends
--

COPY public.auth_group (id, name) FROM stdin;
\.


--
-- TOC entry 3747 (class 0 OID 16656)
-- Dependencies: 248
-- Data for Name: auth_group_permissions; Type: TABLE DATA; Schema: public; Owner: djBackends
--

COPY public.auth_group_permissions (id, group_id, permission_id) FROM stdin;
\.


--
-- TOC entry 3743 (class 0 OID 16640)
-- Dependencies: 244
-- Data for Name: auth_permission; Type: TABLE DATA; Schema: public; Owner: djBackends
--

COPY public.auth_permission (id, name, content_type_id, codename) FROM stdin;
1	Can add log entry	1	add_logentry
2	Can change log entry	1	change_logentry
3	Can delete log entry	1	delete_logentry
4	Can view log entry	1	view_logentry
5	Can add permission	2	add_permission
6	Can change permission	2	change_permission
7	Can delete permission	2	delete_permission
8	Can view permission	2	view_permission
9	Can add group	3	add_group
10	Can change group	3	change_group
11	Can delete group	3	delete_group
12	Can view group	3	view_group
13	Can add content type	4	add_contenttype
14	Can change content type	4	change_contenttype
15	Can delete content type	4	delete_contenttype
16	Can view content type	4	view_contenttype
17	Can add session	5	add_session
18	Can change session	5	change_session
19	Can delete session	5	delete_session
20	Can view session	5	view_session
21	Can add cliente	6	add_cliente
22	Can change cliente	6	change_cliente
23	Can delete cliente	6	delete_cliente
24	Can view cliente	6	view_cliente
25	Can add estado	7	add_estado
26	Can change estado	7	change_estado
27	Can delete estado	7	delete_estado
28	Can view estado	7	view_estado
29	Can add evento	8	add_evento
30	Can change evento	8	change_evento
31	Can delete evento	8	delete_evento
32	Can view evento	8	view_evento
33	Can add raza	9	add_raza
34	Can change raza	9	change_raza
35	Can delete raza	9	delete_raza
36	Can view raza	9	view_raza
37	Can add servicio	10	add_servicio
38	Can change servicio	10	change_servicio
39	Can delete servicio	10	delete_servicio
40	Can view servicio	10	view_servicio
41	Can add tipo estado	11	add_tipoestado
42	Can change tipo estado	11	change_tipoestado
43	Can delete tipo estado	11	delete_tipoestado
44	Can view tipo estado	11	view_tipoestado
45	Can add tipo usuario	12	add_tipousuario
46	Can change tipo usuario	12	change_tipousuario
47	Can delete tipo usuario	12	delete_tipousuario
48	Can view tipo usuario	12	view_tipousuario
49	Can add veterinario	13	add_veterinario
50	Can change veterinario	13	change_veterinario
51	Can delete veterinario	13	delete_veterinario
52	Can view veterinario	13	view_veterinario
53	Can add mascota	14	add_mascota
54	Can change mascota	14	change_mascota
55	Can delete mascota	14	delete_mascota
56	Can view mascota	14	view_mascota
57	Can add log	15	add_log
58	Can change log	15	change_log
59	Can delete log	15	delete_log
60	Can view log	15	view_log
61	Can add cita	16	add_cita
62	Can change cita	16	change_cita
63	Can delete cita	16	delete_cita
64	Can view cita	16	view_cita
65	Can add tipo servicio	17	add_tiposervicio
66	Can change tipo servicio	17	change_tiposervicio
67	Can delete tipo servicio	17	delete_tiposervicio
68	Can view tipo servicio	17	view_tiposervicio
69	Can add tipo mascota	18	add_tipomascota
70	Can change tipo mascota	18	change_tipomascota
71	Can delete tipo mascota	18	delete_tipomascota
72	Can view tipo mascota	18	view_tipomascota
73	Can add tipo cita	19	add_tipocita
74	Can change tipo cita	19	change_tipocita
75	Can delete tipo cita	19	delete_tipocita
76	Can view tipo cita	19	view_tipocita
77	Can add pregunta frecuentes	20	add_preguntafrecuentes
78	Can change pregunta frecuentes	20	change_preguntafrecuentes
79	Can delete pregunta frecuentes	20	delete_preguntafrecuentes
80	Can view pregunta frecuentes	20	view_preguntafrecuentes
81	Can add menu	21	add_menu
82	Can change menu	21	change_menu
83	Can delete menu	21	delete_menu
84	Can view menu	21	view_menu
85	Can add asignacion permiso	22	add_asignacionpermiso
86	Can change asignacion permiso	22	change_asignacionpermiso
87	Can delete asignacion permiso	22	delete_asignacionpermiso
88	Can view asignacion permiso	22	view_asignacionpermiso
89	Can add usuario	23	add_usuario
90	Can change usuario	23	change_usuario
91	Can delete usuario	23	delete_usuario
92	Can view usuario	23	view_usuario
93	Can add permiso	24	add_permiso
94	Can change permiso	24	change_permiso
95	Can delete permiso	24	delete_permiso
96	Can view permiso	24	view_permiso
97	Can add medicina	25	add_medicina
98	Can change medicina	25	change_medicina
99	Can delete medicina	25	delete_medicina
100	Can view medicina	25	view_medicina
101	Can add triaje	26	add_triaje
102	Can change triaje	26	change_triaje
103	Can delete triaje	26	delete_triaje
104	Can view triaje	26	view_triaje
105	Can add receta	27	add_receta
106	Can change receta	27	change_receta
107	Can delete receta	27	delete_receta
108	Can view receta	27	view_receta
109	Can add detalle_receta	28	add_detalle_receta
110	Can change detalle_receta	28	change_detalle_receta
111	Can delete detalle_receta	28	delete_detalle_receta
112	Can view detalle_receta	28	view_detalle_receta
113	Can add restabler usuario	29	add_restablerusuario
114	Can change restabler usuario	29	change_restablerusuario
115	Can delete restabler usuario	29	delete_restablerusuario
116	Can view restabler usuario	29	view_restablerusuario
\.


--
-- TOC entry 3739 (class 0 OID 16525)
-- Dependencies: 240
-- Data for Name: cita; Type: TABLE DATA; Schema: public; Owner: djBackends
--

COPY public.cita (id, fecha_registro, key_cliente_id, key_estado_id, key_mascota_id, key_veterinario_id, key_tipo_cita_id, fecha_inicio, hora_fin, hora_inicio, motivo_consulta, key_servicio_id, motivo_cancelacion, diagnostico, observacion_sistema, recomendacion, tiempo_estimado) FROM stdin;
3	2024-04-07 00:31:16.529762+00	2	7	2	1	2	2024-04-10	10:00	9:30	BAÑO A MI GATO	2		\N	\N	\N	\N
2	2024-04-07 00:26:01.232862+00	3	6	1	1	1	2024-04-10	11:15	11:0	CONSULTA CANINA	2	\N	\N	\N	\N	\N
4	2024-04-07 00:40:56.28136+00	2	6	2	1	2	2024-04-08	09:30	9:0	CONSULTA CANINA	2	\N	Se diagnosticó dermatitis alérgica, basado en la presencia de prurito intenso, eritema y lesiones cutáneas características, así como en la exclusión de otras posibles causas. 	En la revisión por sistemas del perro, se encontraron músculos y articulaciones sin anomalías aparentes, una respiración y frecuencia cardíaca dentro de los parámetros normales, un sistema digestivo sin problemas evidentes, una función neurológica y genitourinaria intacta, una piel y pelaje en buen estado, y ojos y oídos sin irregularidades.	Es importante mantener una dieta equilibrada, evitar alérgenos conocidos y utilizar champús específicos para piel sensible. Además, asegúrese de mantener a su perro bien hidratado y evitar rascarse para prevenir infecciones secundarias.\n	\N
16	2024-06-06 05:58:52.513371+00	2	6	11	1	1	2024-06-07	11:00	10:30	Mi mascota presenta pequeñas erupciones en la piel.	2	\N	Se diagnosticó dermatitis alérgica, basado en la presencia de prurito intenso, eritema y lesiones cutáneas características, así como en la exclusión de otras posibles causas. 	En la revisión por sistemas del perro, se encontraron músculos y articulaciones sin anomalías aparentes, una respiración y frecuencia cardíaca dentro de los parámetros normales, un sistema digestivo sin problemas evidentes, una función neurológica y genitourinaria intacta, una piel y pelaje en buen estado, y ojos y oídos sin irregularidades.\n \n	Es importante mantener una dieta equilibrada, evitar alérgenos conocidos y utilizar champús específicos para piel sensible. Además, asegúrese de mantener a su perro bien hidratado y evitar rascarse para prevenir infecciones secundarias.	00:00:50
1	2024-04-07 00:15:59.274382+00	2	9	2	3	1	2024-04-09	09:05	8:45	BAÑO ESTÉTICO	11	\N	\N	\N	\N	\N
6	2024-04-07 05:15:08.081794+00	2	6	11	1	1	2024-04-10	10:30	10:0	BAÑO ESTÉTICO	10	\N	DIAGNOSTICO	\N	RECOMENDACION	\N
5	2024-04-07 01:45:57.584+00	15	6	10	3	1	2024-04-10	09:30	9:0	CONSULTA FELINA	1	\N	Se diagnosticó dermatitis alérgica, basado en la presencia de prurito intenso, eritema y lesiones cutáneas características, así como en la exclusión de otras posibles causas. 	En la revisión por sistemas del perro, se encontraron músculos y articulaciones sin anomalías aparentes, una respiración y frecuencia cardíaca dentro de los parámetros normales, un sistema digestivo sin problemas evidentes, una función neurológica y genitourinaria intacta, una piel y pelaje en buen estado, y ojos y oídos sin irregularidades.	Es importante mantener una dieta equilibrada, evitar alérgenos conocidos y utilizar champús específicos para piel sensible. Además, asegúrese de mantener a su perro bien hidratado y evitar rascarse para prevenir infecciones secundarias.	\N
7	2024-04-07 16:32:09.096511+00	2	9	12	1	1	2024-04-11	11:30	11:0	CONSULTA	2	\N	\N	\N	\N	\N
8	2024-04-28 02:51:54.961619+00	2	9	11	2	1	2024-04-27	09:11	8:51	Consulta	4	\N	\N	\N	\N	\N
9	2024-04-28 02:53:14.560827+00	2	9	11	4	1	2024-04-27	12:13	11:53	Consulta	5	\N	\N	\N	\N	\N
10	2024-04-28 02:55:07.981265+00	14	9	13	2	1	2024-04-27	11:14	10:54	CONSULTA	7	\N	\N	\N	\N	\N
12	2024-04-28 02:58:00.845006+00	5	9	7	2	2	2024-04-27	12:27	11:57	ECOGRAFÍA	13	\N	\N	\N	\N	\N
13	2024-05-09 05:28:16.156434+00	2	6	2	2	1	2024-05-09	09:47	9:27	CONSULTA	14	\N	\N	\N	\N	\N
14	2024-05-22 02:38:47.459164+00	15	6	10	1	2	2024-06-05	10:30	10:0	PERFIL RENAL	4	\N	\N	\N	\N	\N
15	2024-05-22 03:22:13.211994+00	2	9	12	2	1	2024-05-23	09:20	9:0	CONSULTA	3	\N	\N	\N	\N	\N
11	2024-04-28 02:56:28.245418+00	12	5	4	1	1	2024-04-27	10:36	9:56	ECOGRAFIA	14	\N	\N	\N	\N	\N
18	2024-06-06 20:43:58.742398+00	16	9	14	1	1	2024-06-07	11:15	10:45	CONSULTA	2	\N	\N	\N	\N	00:03:27
19	2024-06-06 20:45:57.448621+00	16	9	14	1	2	2024-06-08	16:45	15:45	CONSULTA	5	\N	\N	\N	\N	00:00:27
17	2024-06-06 20:36:54.067297+00	16	6	14	1	1	2024-06-07	10:45	10:0	CONSULTA	8	\N	\N	\N	\N	00:01:38
\.


--
-- TOC entry 3719 (class 0 OID 16407)
-- Dependencies: 220
-- Data for Name: cliente; Type: TABLE DATA; Schema: public; Owner: djBackends
--

COPY public.cliente (id, dni, nombre, apellido, direccion, num_cel, correo, fecha_registro, key_estado_id, sexo) FROM stdin;
3	45236895	NELIDA	LOPEZ SANCHEZ	Calle Trujillo 523	965231485	nelidalop@gmail.com	2024-04-06 02:40:58.17109+00	1	Femenino
4	02861154	MARIELA	JUAREZ VILLEGAS	TAMBOGRANDE	965842356	maryjv@gmail.com	2024-04-06 02:45:51.260704+00	1	Femenino
5	72218778	LEILY GUADALUPE	RAMOS MORE	SULLANA	956231452	leilyrm@gmail.com	2024-04-06 02:48:39.900189+00	1	Femenino
6	80297173	JUANA AURELIA	SILVA YAMUNAQUE	MARCAVELICA	963214589	juanasilva@gmail.com	2024-04-06 02:53:44.053312+00	1	Femenino
7	02861157	MARIA CARMEN	LOPEZ HURTADO	CALLE BOLOGNESI 235	985632145	mariacarmen@hotmail.com	2024-04-06 02:55:20.887923+00	1	Femenino
8	02415638	SHIOMARA	NEIRA CANAZAS	Calle Buenos Aires 523	932541653	shioneira@gmail.com	2024-04-06 02:56:22.960234+00	1	Femenino
9	45236154	NOEMI	CORONEL YUPANQUI	CALLE PIURA 235	965234562	NOE768@GMAIL.COM	2024-04-06 02:57:32.028069+00	1	Femenino
10	02896315	EDME MARTHA	GARCIA MANDAMIENTOS	CALLE MORROPON 235	965831256	EDMEGAR@GMAIL.COM	2024-04-06 02:58:20.483551+00	1	Femenino
11	72257968	CARLOS MANUEL	OJEDA VIERA	CALLE APURIMAC 458	936542358	CARMAN@GMAIL.COM	2024-04-06 02:59:30.94596+00	1	Masculino
12	024531523	ALBERTO	GIRON CARRION	CALLE PAITA 563	959647859	ALBERTG@GMAIL.COM	2024-04-06 03:01:02.355219+00	1	Masculino
13	02563189	JAVIER	BERRU ACARO	AVENIDA GRAU 238	963158963	JAVIERBERRA@GMAIL.COM	2024-04-06 03:03:58.0607+00	1	Masculino
14	02785152	MIRANDA	GIRON	AVENIDA SAN MARTIN 325	985623564	MIRANDA@GMAIL.COM	2024-04-06 04:24:39.278718+00	1	Masculino
15	74526358	SOFIA	MONTES CARREÑO	\N	987456328	SOFIMONTE@GMAIL.COM	2024-04-07 01:43:51.696602+00	1	Femenino
2	72020362	MIGUEL IVAN	BECERRA GUERRERO	SULLANA	963256842	miguelbec@gmail.com	2024-04-04 21:43:05.60966+00	1	Masculino
16	02569475	JOSE	CAMPOS SOSA	CALLE SAN MARTIN 256	9362156356	josecamp@gmail.com	2024-06-06 20:10:26.429559+00	1	Masculino
\.


--
-- TOC entry 3775 (class 0 OID 17014)
-- Dependencies: 276
-- Data for Name: detalle_receta; Type: TABLE DATA; Schema: public; Owner: djBackends
--

COPY public.detalle_receta (id, tratamiento, key_medicamento_id, key_receta_id) FROM stdin;
1	1 comprimido cada 8 horas	3	2
2	BAÑAR CON ESTE MEDICAMENTO UNA VEZ AL MES	9	3
3	1 comprimido cada 8 horas	3	4
4	5 ml cada 6 horas	1	4
5	1 comprimido cada 8 horas	3	7
\.


--
-- TOC entry 3741 (class 0 OID 16618)
-- Dependencies: 242
-- Data for Name: django_admin_log; Type: TABLE DATA; Schema: public; Owner: djBackends
--

COPY public.django_admin_log (id, action_time, object_id, object_repr, action_flag, change_message, content_type_id, user_id) FROM stdin;
\.


--
-- TOC entry 3717 (class 0 OID 16398)
-- Dependencies: 218
-- Data for Name: django_content_type; Type: TABLE DATA; Schema: public; Owner: djBackends
--

COPY public.django_content_type (id, app_label, model) FROM stdin;
1	admin	logentry
2	auth	permission
3	auth	group
4	contenttypes	contenttype
5	sessions	session
6	app_veterinaria	cliente
7	app_veterinaria	estado
8	app_veterinaria	evento
9	app_veterinaria	raza
10	app_veterinaria	servicio
11	app_veterinaria	tipoestado
12	app_veterinaria	tipousuario
13	app_veterinaria	veterinario
14	app_veterinaria	mascota
15	app_veterinaria	log
16	app_veterinaria	cita
17	app_veterinaria	tiposervicio
18	app_veterinaria	tipomascota
19	app_veterinaria	tipocita
20	app_veterinaria	preguntafrecuentes
21	app_veterinaria	menu
22	app_veterinaria	asignacionpermiso
23	app_veterinaria	usuario
24	app_veterinaria	permiso
25	app_veterinaria	medicina
26	app_veterinaria	triaje
27	app_veterinaria	receta
28	app_veterinaria	detalle_receta
29	app_veterinaria	restablerusuario
\.


--
-- TOC entry 3715 (class 0 OID 16389)
-- Dependencies: 216
-- Data for Name: django_migrations; Type: TABLE DATA; Schema: public; Owner: djBackends
--

COPY public.django_migrations (id, app, name, applied) FROM stdin;
1	contenttypes	0001_initial	2024-04-04 20:47:33.144721+00
2	app_veterinaria	0001_initial	2024-04-04 20:47:33.844931+00
3	admin	0001_initial	2024-04-04 20:47:33.907731+00
4	admin	0002_logentry_remove_auto_add	2024-04-04 20:47:33.924781+00
5	admin	0003_logentry_add_action_flag_choices	2024-04-04 20:47:33.939637+00
6	contenttypes	0002_remove_content_type_name	2024-04-04 20:47:33.987156+00
7	auth	0001_initial	2024-04-04 20:47:34.144074+00
8	auth	0002_alter_permission_name_max_length	2024-04-04 20:47:34.163528+00
9	auth	0003_alter_user_email_max_length	2024-04-04 20:47:34.179269+00
10	auth	0004_alter_user_username_opts	2024-04-04 20:47:34.1961+00
11	auth	0005_alter_user_last_login_null	2024-04-04 20:47:34.215451+00
12	auth	0006_require_contenttypes_0002	2024-04-04 20:47:34.225925+00
13	auth	0007_alter_validators_add_error_messages	2024-04-04 20:47:34.255606+00
14	auth	0008_alter_user_username_max_length	2024-04-04 20:47:34.282642+00
15	auth	0009_alter_user_last_name_max_length	2024-04-04 20:47:34.309591+00
16	auth	0010_alter_group_name_max_length	2024-04-04 20:47:34.345791+00
17	auth	0011_update_proxy_permissions	2024-04-04 20:47:34.398188+00
18	auth	0012_alter_user_first_name_max_length	2024-04-04 20:47:34.423123+00
19	app_veterinaria	0002_rename_nombre_servcio_servicio_nombre_servicio	2024-04-04 20:47:34.443797+00
20	app_veterinaria	0003_servicio_key_estado	2024-04-04 20:47:34.499638+00
21	app_veterinaria	0004_veterinario_dni	2024-04-04 20:47:34.528553+00
22	app_veterinaria	0005_tiposervicio_servicio_key_tipo_servicio	2024-04-04 20:47:34.606081+00
23	app_veterinaria	0006_tiposervicio_key_estado	2024-04-04 20:47:34.652493+00
24	app_veterinaria	0007_cliente_sexo_veterinario_sexo	2024-04-04 20:47:34.704876+00
25	app_veterinaria	0008_alter_cliente_num_cel	2024-04-04 20:47:34.771083+00
26	app_veterinaria	0009_raza_key_estado	2024-04-04 20:47:34.822807+00
27	app_veterinaria	0010_tipomascota_mascota_key_tipo_mascota	2024-04-04 20:47:34.895004+00
28	app_veterinaria	0011_tipomascota_key_estado	2024-04-04 20:47:34.955006+00
29	app_veterinaria	0012_tipocita_delete_programacioncita_cita_key_tipo_cita	2024-04-04 20:47:35.037877+00
30	app_veterinaria	0013_tipocita_key_estado	2024-04-04 20:47:35.075594+00
31	app_veterinaria	0014_cita_fecha_inicio_cita_hora_fin_cita_hora_inicio_and_more	2024-04-04 20:47:35.17798+00
32	app_veterinaria	0015_cita_motivo_consulta	2024-04-04 20:47:35.210752+00
33	app_veterinaria	0016_cita_key_servicio	2024-04-04 20:47:35.25647+00
34	app_veterinaria	0017_cita_motivo_cancelacion	2024-04-04 20:47:35.278461+00
35	app_veterinaria	0018_preguntafrecuentes	2024-04-04 20:47:35.333466+00
36	app_veterinaria	0019_menu_asignacionpermiso	2024-04-04 20:47:35.410758+00
37	app_veterinaria	0020_tipousuario_action	2024-04-04 20:47:35.427872+00
38	app_veterinaria	0021_usuario_key_estado	2024-04-04 20:47:35.556932+00
39	app_veterinaria	0022_alter_usuario_usuario	2024-04-04 20:47:35.61753+00
40	app_veterinaria	0023_usuario_num_documento	2024-04-04 20:47:35.663748+00
41	app_veterinaria	0024_remove_asignacionpermiso_key_usuario_and_more	2024-04-04 20:47:35.779166+00
42	app_veterinaria	0025_usuario_fecha_session	2024-04-04 20:47:35.812419+00
43	app_veterinaria	0026_alter_usuario_num_documento	2024-04-04 20:47:35.867486+00
44	app_veterinaria	0027_remove_usuario_apellido_remove_usuario_correo_and_more	2024-04-04 20:47:36.000547+00
45	app_veterinaria	0028_remove_log_key_usuario_delete_usuario	2024-04-04 20:47:36.038104+00
46	app_veterinaria	0029_usuario_log_key_usuario	2024-04-04 20:47:36.284815+00
47	app_veterinaria	0030_rename_num_documento_usuario_document_number_and_more	2024-04-04 20:47:36.390848+00
48	app_veterinaria	0031_usuario_status	2024-04-04 20:47:36.445373+00
49	app_veterinaria	0032_rename_usertype_usuario_user_type	2024-04-04 20:47:36.48603+00
50	app_veterinaria	0033_alter_usuario_groups_alter_usuario_user_permissions	2024-04-04 20:47:36.549842+00
51	app_veterinaria	0034_alter_usuario_last_login	2024-04-04 20:47:36.591939+00
52	app_veterinaria	0035_permiso_asignacionpermiso_key_permiso	2024-04-04 20:47:36.71978+00
53	app_veterinaria	0036_alter_permiso_table	2024-04-04 20:47:36.762651+00
54	app_veterinaria	0037_medicina_cita_diganostico_cita_observacion_sistema_and_more	2024-04-04 20:47:37.024767+00
55	app_veterinaria	0038_remove_receta_key_medicamento_and_more	2024-04-04 20:47:37.244474+00
56	app_veterinaria	0039_alter_detalle_receta_table	2024-04-04 20:47:37.268755+00
57	app_veterinaria	0040_rename_diganostico_cita_diagnostico	2024-04-04 20:47:37.307583+00
58	sessions	0001_initial	2024-04-04 20:47:37.358117+00
59	app_veterinaria	0041_restablerusuario	2024-06-05 03:00:30.750637+00
60	app_veterinaria	0042_cita_tiempo_estimado	2024-06-05 03:00:30.774733+00
\.


--
-- TOC entry 3776 (class 0 OID 17034)
-- Dependencies: 277
-- Data for Name: django_session; Type: TABLE DATA; Schema: public; Owner: djBackends
--

COPY public.django_session (session_key, session_data, expire_date) FROM stdin;
\.


--
-- TOC entry 3721 (class 0 OID 16416)
-- Dependencies: 222
-- Data for Name: estado; Type: TABLE DATA; Schema: public; Owner: djBackends
--

COPY public.estado (id, nombre, abreviatura, descripcion, accion, color, icon, key_tipo_estado_id) FROM stdin;
1	ACTIVO	AC	\N	\N	success	\N	3
3	INACTIVO	INA	\N	\N	error	\N	3
4	DISPONIBLE	DISP	\N	\N	success	tabler-checks	3
2	ANULADO 	AN	\N	\N	error	tabler-clock-off	1
5	CONFIRMADO	CONF	\N	\N	info	tabler-progress-check	4
6	COMPLETADO	COMP	\N	\N	success	tabler-checklist	4
9	SE REQUIERE CONFIRMACIÓN	SRC	\N	\N	confirmac	tabler-alert-triangle	3
8	AUSENCIA DE PACIENTE	ASPAC	\N	\N	primary	tabler-user-question	4
7	CANCELADO	CANC	\N	\N	secundary	tabler-report-off	4
\.


--
-- TOC entry 3723 (class 0 OID 16425)
-- Dependencies: 224
-- Data for Name: evento; Type: TABLE DATA; Schema: public; Owner: djBackends
--

COPY public.evento (id, nombre, color, icon) FROM stdin;
1	INSERCIÓN	success	tabler-plus
2	MODIFICACIÓN	warning	tabler-edit
3	ELIMINACIÓN LOGICA	error	tabler-trash
4	ELIMINACIÓN FÍSICA	error	tabler-block
5	IMPORTAR	primary	tabler-database-import
6	RESTAURACIÓN	success	tabler-cloud-check
\.


--
-- TOC entry 3737 (class 0 OID 16506)
-- Dependencies: 238
-- Data for Name: log; Type: TABLE DATA; Schema: public; Owner: djBackends
--

COPY public.log (id, nombre_tabla, key_tabla, fecha_hora_registro, descripcion, key_evento_id, key_usuario_id) FROM stdin;
1	usuario	1	2024-04-04 21:16:41.355592+00	el usuario fue registrado con exito	1	\N
2	cliente	1	2024-04-04 21:16:41.507908+00	El cliente por nombre GLENDY GERALDINE fue registrado con exito	1	\N
3	usuario	2	2024-04-04 21:43:05.550285+00	el usuario fue registrado con exito	1	\N
4	cliente	2	2024-04-04 21:43:05.6144+00	El cliente por nombre MIGUEL IVAN fue registrado con exito	1	\N
5	tipo_servicio	1	2024-04-04 21:51:54.21785+00	El tipo de servicio por nombre Laboratorio - Pefiles fue registrado con exito	1	\N
6	tipo_servicio	2	2024-04-04 21:52:04.452264+00	El tipo de servicio por nombre Exámenes Especiales fue registrado con exito	1	\N
7	tipo_servicio	3	2024-04-04 21:52:13.418365+00	El tipo de servicio por nombre Exámenes Bioquímicos fue registrado con exito	1	\N
8	tipo_servicio	4	2024-04-04 21:52:24.395797+00	El tipo de servicio por nombre Otros fue registrado con exito	1	\N
9	tipo_servicio	5	2024-04-04 21:52:35.671734+00	El tipo de servicio por nombre SPA fue registrado con exito	1	\N
10	tipo_servicio	6	2024-04-04 21:52:44.271944+00	El tipo de servicio por nombre Ecografías fue registrado con exito	1	\N
11	tipo_servicio	7	2024-04-04 21:52:53.090596+00	El tipo de servicio por nombre Consulta general fue registrado con exito	1	\N
12	pregunta_frecuente	1	2024-04-04 22:21:16.869514+00	el registro por asunto 1.\t¿Cuál es la modalidad de pago de los servicios? fue guardado con exito	1	\N
13	pregunta_frecuente	2	2024-04-04 22:21:34.992926+00	el registro por asunto 2.\t¿Cómo puedo cancelar o modificar mi cita una vez que la he reservado? fue guardado con exito	1	\N
14	pregunta_frecuente	3	2024-04-04 22:21:49.75981+00	el registro por asunto 3.\t¿Cuál es el tiempo de duración de cada servicio? fue guardado con exito	1	\N
15	pregunta_frecuente	4	2024-04-04 22:22:04.066937+00	el registro por asunto 4.\t¿Hay algún costo asociado con la cancelación de citas? fue guardado con exito	1	\N
16	pregunta_frecuente	5	2024-04-04 22:22:19.926471+00	el registro por asunto 5.\t¿Cuáles son los requisitos o documentos necesarios para la cita? fue guardado con exito	1	\N
17	pregunta_frecuente	6	2024-04-04 22:22:31.853691+00	el registro por asunto 6.\t¿Puedo ver mi historial de citas anteriores? fue guardado con exito	1	\N
18	pregunta_frecuente	7	2024-04-04 22:22:44.928265+00	el registro por asunto 7.\t¿Puedo solicitar una cita de emergencia? fue guardado con exito	1	\N
19	pregunta_frecuente	8	2024-04-04 22:22:58.674934+00	el registro por asunto 8.\t¿Cuánto tiempo de antelación debo reservar una cita? fue guardado con exito	1	\N
20	usuario	2	2024-04-04 22:23:50.748366+00	El usuario miguel.becerra sus datos fueron actualizados con exito	2	\N
21	veterinario	1	2024-04-04 22:34:49.405181+00	El personal por nombre JOSE ALEXANDER fue registrado con exito	1	\N
22	veterinario	2	2024-04-04 22:39:35.101729+00	El personal por nombre BRONIA INDIRA fue registrado con exito	1	\N
23	veterinario	3	2024-04-04 22:40:38.539864+00	El personal por nombre MARICIELO fue registrado con exito	1	\N
24	veterinario	4	2024-04-04 22:42:46.737816+00	El personal por nombre MARIA LOURDES fue registrado con exito	1	\N
25	tipo_servicio	1	2024-04-04 22:44:35.495406+00	El tipo de servicio por nombre Laboratorio - Perfiles fue modificado con exito	2	\N
26	servicio	1	2024-04-04 22:45:14.348581+00	El servicio por nombre Consultas caninas fue registrado con exito	1	\N
27	servicio	2	2024-04-04 22:45:44.42396+00	El servicio por nombre CONSULTAS CANINAS fue registrado con exito	1	\N
28	servicio	1	2024-04-04 22:46:01.71928+00	El servicio por nombre Consultas felinas fue modificado con exito	2	\N
29	servicio	2	2024-04-04 22:47:32.491854+00	El servicio por nombre CONSULTA CANINAS fue modificado con exito	2	\N
30	servicio	1	2024-04-04 22:47:40.132036+00	El servicio por nombre Consulta felina fue modificado con exito	2	\N
31	servicio	3	2024-04-04 22:48:10.484361+00	El servicio por nombre Consulta dermatológica fue registrado con exito	1	\N
32	servicio	4	2024-04-04 22:48:57.784004+00	El servicio por nombre Perfil renal simple completo fue registrado con exito	1	\N
33	servicio	5	2024-04-04 22:49:33.760249+00	El servicio por nombre Perfil hepático completo fue registrado con exito	1	\N
34	servicio	2	2024-04-04 22:49:43.498789+00	El servicio por nombre CONSULTA CANINA fue modificado con exito	2	\N
35	servicio	3	2024-04-04 22:49:52.935777+00	El servicio por nombre Consulta dermatológica fue modificado con exito	2	\N
36	servicio	4	2024-04-04 22:49:58.216881+00	El servicio por nombre Perfil renal simple completo fue modificado con exito	2	\N
37	servicio	5	2024-04-04 22:50:01.858518+00	El servicio por nombre Perfil hepático completo fue modificado con exito	2	\N
38	servicio	6	2024-04-04 22:50:37.212712+00	El servicio por nombre Perfil lipídico fue registrado con exito	1	\N
39	servicio	7	2024-04-04 22:51:29.755615+00	El servicio por nombre Consulta traumatológica fue registrado con exito	1	\N
40	servicio	8	2024-04-04 22:52:50.95123+00	El servicio por nombre Profilaxis fue registrado con exito	1	\N
41	servicio	9	2024-04-04 22:58:27.439167+00	El servicio por nombre BAÑOS MEDICADOS fue registrado con exito	1	\N
42	servicio	10	2024-04-04 22:59:10.548248+00	El servicio por nombre BAÑOS ESTÉTICOS fue registrado con exito	1	\N
43	servicio	11	2024-04-04 22:59:29.029908+00	El servicio por nombre CORTES HIGIENICOS fue registrado con exito	1	\N
44	servicio	12	2024-04-04 22:59:45.707446+00	El servicio por nombre CORTES ESTÉTICOS fue registrado con exito	1	\N
45	servicio	13	2024-04-04 23:02:06.175157+00	El servicio por nombre ECOGRAFIA ABDOMINAL fue registrado con exito	1	\N
46	servicio	14	2024-04-04 23:02:33.220853+00	El servicio por nombre ECOGRAFIA GESTACIONAL fue registrado con exito	1	\N
47	servicio	15	2024-04-04 23:03:00.737911+00	El servicio por nombre RASPADO CUTÁNEO fue registrado con exito	1	\N
48	veterinario	1	2024-04-04 23:05:29.542752+00	El personal por nombre JOSE ALEXANDER fue modificado con exito	2	\N
49	veterinario	2	2024-04-04 23:05:33.404429+00	El personal por nombre BRONIA INDIRA fue modificado con exito	2	\N
50	veterinario	4	2024-04-04 23:05:36.742715+00	El personal por nombre MARIA LOURDES fue modificado con exito	2	\N
51	veterinario	3	2024-04-04 23:05:42.001901+00	El personal por nombre MARICIELO fue modificado con exito	2	\N
52	pregunta_frecuente	8	2024-04-04 23:09:19.995977+00	El asunto por nombre 8.\t¿Con cuánto tiempo de antelación debo reservar una cita? fue modificado con exito	2	\N
53	pregunta_frecuente	1	2024-04-04 23:09:54.542103+00	El asunto por nombre 1.\t¿Cuál es la modalidad de pago de los servicios? fue modificado con exito	2	\N
54	pregunta_frecuente	1	2024-04-04 23:10:10.79722+00	El asunto por nombre ¿Cuál es la modalidad de pago de los servicios? fue modificado con exito	2	\N
115	servicio	8	2024-04-06 03:48:37.158242+00	El servicio por nombre PROFILAXIS fue modificado con exito	2	\N
55	pregunta_frecuente	8	2024-04-04 23:10:15.070174+00	El asunto por nombre ¿Con cuánto tiempo de antelación debo reservar una cita? fue modificado con exito	2	\N
56	pregunta_frecuente	7	2024-04-04 23:10:19.755945+00	El asunto por nombre ¿Puedo solicitar una cita de emergencia? fue modificado con exito	2	\N
57	pregunta_frecuente	2	2024-04-04 23:10:26.967297+00	El asunto por nombre ¿Cómo puedo cancelar o modificar mi cita una vez que la he reservado? fue modificado con exito	2	\N
58	pregunta_frecuente	3	2024-04-04 23:10:31.240225+00	El asunto por nombre ¿Cuál es el tiempo de duración de cada servicio? fue modificado con exito	2	\N
59	pregunta_frecuente	4	2024-04-04 23:10:37.118552+00	El asunto por nombre ¿Hay algún costo asociado con la cancelación de citas? fue modificado con exito	2	\N
60	pregunta_frecuente	5	2024-04-04 23:10:41.839225+00	El asunto por nombre ¿Cuáles son los requisitos o documentos necesarios para la cita? fue modificado con exito	2	\N
61	pregunta_frecuente	6	2024-04-04 23:10:48.298935+00	El asunto por nombre ¿Puedo ver mi historial de citas anteriores? fue modificado con exito	2	\N
62	usuario	3	2024-04-04 23:12:38.351888+00	el usuario fue registrado con exito	1	\N
63	tipo_mascota	1	2024-04-04 23:18:35.94968+00	El tipo de mascota por nombre PERRO fue registrado con exito	1	\N
64	tipo_mascota	2	2024-04-04 23:18:41.944116+00	El tipo de mascota por nombre GATO fue registrado con exito	1	\N
65	raza	1	2024-04-04 23:23:12.209821+00	La raza por nombre Husky Siberiano fue registrado con exito	1	\N
66	raza	2	2024-04-04 23:23:32.323828+00	La raza por nombre Bulldog Inglés fue registrado con exito	1	\N
67	raza	3	2024-04-04 23:23:52.58194+00	La raza por nombre Dálmata fue registrado con exito	1	\N
68	raza	4	2024-04-04 23:24:13.153344+00	La raza por nombre Salchicha fue registrado con exito	1	\N
69	raza	5	2024-04-04 23:24:30.821004+00	La raza por nombre Bóxer fue registrado con exito	1	\N
70	raza	6	2024-04-04 23:24:48.090337+00	La raza por nombre Pastor Alemán fue registrado con exito	1	\N
71	raza	7	2024-04-04 23:25:11.525457+00	La raza por nombre Pomerania fue registrado con exito	1	\N
72	raza	8	2024-04-04 23:30:19.125856+00	La raza por nombre Poodle fue registrado con exito	1	\N
73	cliente	3	2024-04-06 02:40:58.289416+00	El cliente por nombre NELIDA fue registrado con exito	1	\N
74	cliente	1	2024-04-06 02:41:31.889871+00	El cliente por nombre GLENDY GERALDINE fue modificado con exito	2	\N
75	cliente	1	2024-04-06 02:41:46.957521+00	El cliente por nombre Geraldine fue modificado con exito	2	\N
76	cliente	2	2024-04-06 02:42:13.088609+00	El cliente por nombre MIGUEL IVAN fue modificado con exito	2	\N
77	cliente	4	2024-04-06 02:45:51.274247+00	El cliente por nombre MARIELA fue registrado con exito	1	\N
78	cliente	5	2024-04-06 02:48:39.905943+00	El cliente por nombre LEILY GUADALUPE fue registrado con exito	1	\N
79	cliente	6	2024-04-06 02:53:44.058386+00	El cliente por nombre JUANA AURELIA fue registrado con exito	1	\N
80	cliente	7	2024-04-06 02:55:20.894751+00	El cliente por nombre MARIA CARMEN fue registrado con exito	1	\N
81	cliente	8	2024-04-06 02:56:22.967478+00	El cliente por nombre SHIOMARA fue registrado con exito	1	\N
82	cliente	9	2024-04-06 02:57:32.033278+00	El cliente por nombre NOEMI fue registrado con exito	1	\N
83	cliente	10	2024-04-06 02:58:20.490243+00	El cliente por nombre EDME MARTHA fue registrado con exito	1	\N
84	cliente	11	2024-04-06 02:59:30.951887+00	El cliente por nombre CARLOS MANUEL fue registrado con exito	1	\N
85	cliente	12	2024-04-06 03:01:02.360375+00	El cliente por nombre ALBERTO fue registrado con exito	1	\N
86	cliente	13	2024-04-06 03:03:58.068603+00	El cliente por nombre JAVIER fue registrado con exito	1	\N
87	cliente	1	2024-04-06 03:04:35.835671+00	El cliente fue eliminado con exito	4	\N
88	mascota	1	2024-04-06 03:14:34.976235+00	La mascota por nombre OSO fue registrado con exito	1	\N
89	mascota	2	2024-04-06 03:16:38.362283+00	La mascota por nombre ROCKY fue registrado con exito	1	\N
90	mascota	3	2024-04-06 03:17:50.061398+00	La mascota por nombre KAYSER fue registrado con exito	1	\N
91	mascota	4	2024-04-06 03:20:11.881214+00	La mascota por nombre LOBO fue registrado con exito	1	\N
92	raza	9	2024-04-06 03:27:37.347655+00	La raza por nombre Persa fue registrado con exito	1	\N
93	raza	10	2024-04-06 03:27:55.398209+00	La raza por nombre Siamés fue registrado con exito	1	\N
94	raza	11	2024-04-06 03:28:14.04848+00	La raza por nombre Maine Coon fue registrado con exito	1	\N
95	raza	12	2024-04-06 03:28:34.170597+00	La raza por nombre Bengalí fue registrado con exito	1	\N
96	raza	13	2024-04-06 03:28:53.66398+00	La raza por nombre Sphynx fue registrado con exito	1	\N
97	raza	14	2024-04-06 03:29:15.524542+00	La raza por nombre Exótico fue registrado con exito	1	\N
98	raza	15	2024-04-06 03:30:24.442748+00	La raza por nombre MESTIZO fue registrado con exito	1	\N
99	raza	16	2024-04-06 03:32:17.316145+00	La raza por nombre DESCONOCIDA fue registrado con exito	1	\N
100	raza	16	2024-04-06 03:33:24.745661+00	La raza por nombre DESCONOCIDA fue modificado con exito	2	\N
101	mascota	3	2024-04-06 03:35:16.744802+00	La mascota por nombre KAYSER fue modificado con exito	2	\N
102	mascota	5	2024-04-06 03:35:50.124053+00	La mascota por nombre MININA fue registrado con exito	1	\N
103	mascota	4	2024-04-06 03:36:10.757984+00	La mascota por nombre LOBO fue modificado con exito	2	\N
104	mascota	5	2024-04-06 03:36:24.192629+00	La mascota por nombre MININA fue modificado con exito	2	\N
105	mascota	5	2024-04-06 03:36:38.545356+00	La mascota por nombre MININA fue modificado con exito	2	\N
106	mascota	6	2024-04-06 03:38:31.576777+00	La mascota por nombre CARAMELO fue registrado con exito	1	\N
107	mascota	7	2024-04-06 03:46:44.896294+00	La mascota por nombre BRONCO fue registrado con exito	1	\N
108	servicio	1	2024-04-06 03:47:25.744141+00	El servicio por nombre CONSULTA FELINA fue modificado con exito	2	\N
109	servicio	2	2024-04-06 03:47:30.3214+00	El servicio por nombre CONSULTA CANINA fue modificado con exito	2	\N
110	servicio	3	2024-04-06 03:47:42.064088+00	El servicio por nombre CONSULTA DERMATOLÓGICA fue modificado con exito	2	\N
111	servicio	4	2024-04-06 03:47:55.353782+00	El servicio por nombre PERFIL RENAL SIMPLE COMPLETO fue modificado con exito	2	\N
112	servicio	5	2024-04-06 03:48:07.794424+00	El servicio por nombre PERFIL HEPÁTICO COMPLETO fue modificado con exito	2	\N
113	servicio	6	2024-04-06 03:48:17.848033+00	El servicio por nombre PERFIL LIPÍDICO fue modificado con exito	2	\N
114	servicio	7	2024-04-06 03:48:29.362632+00	El servicio por nombre CONSULTA TRAUMATOLÓGICA fue modificado con exito	2	\N
181	cita	1	2024-04-07 01:56:23.131787+00	La cita actualizada con exito	2	\N
116	servicio	9	2024-04-06 03:51:59.210838+00	El servicio por nombre BAÑO MEDICADO fue modificado con exito	2	\N
117	servicio	10	2024-04-06 03:52:04.054155+00	El servicio por nombre BAÑO ESTÉTICO fue modificado con exito	2	\N
118	servicio	11	2024-04-06 03:52:08.484914+00	El servicio por nombre CORTE HIGIENICO fue modificado con exito	2	\N
119	servicio	12	2024-04-06 03:52:13.261303+00	El servicio por nombre CORTE ESTÉTICO fue modificado con exito	2	\N
120	pregunta_frecuente	3	2024-04-06 03:56:15.229217+00	El asunto por nombre ¿Cuál es el tiempo de duración de cada servicio? fue modificado con exito	2	\N
121	pregunta_frecuente	2	2024-04-06 03:57:32.299145+00	El asunto por nombre ¿Cómo puedo cancelar o modificar mi cita una vez que la he reservado? fue modificado con exito	2	\N
122	pregunta_frecuente	6	2024-04-06 03:58:14.925497+00	El asunto por nombre ¿Puedo ver mi historial de citas anteriores? fue modificado con exito	2	\N
123	tipo_mascota	1	2024-04-06 04:04:55.603574+00	Los datos fueron anulado con exito	3	\N
124	tipo_mascota	1	2024-04-06 04:10:03.829432+00	Los datos fueron restaurado con exito	6	\N
125	servicio	13	2024-04-06 04:11:28.136055+00	El servicio por nombre ECOGRAFIA ABDOMINAL fue modificado con exito	2	\N
126	usuario	4	2024-04-06 04:24:39.167373+00	el usuario fue registrado con exito	1	\N
127	cliente	14	2024-04-06 04:24:39.287309+00	El cliente por nombre MIRANDA fue registrado con exito	1	\N
128	mascota	8	2024-04-06 04:26:55.48038+00	La mascota por nombre MIMI fue registrado con exito	1	\N
129	mascota	8	2024-04-06 04:28:47.579891+00	La mascota por nombre MIMI fue modificado con exito	2	\N
130	cliente	14	2024-04-06 04:37:10.026623+00	El cliente por nombre MIRANDA fue modificado con exito	2	\N
131	mascota	9	2024-04-06 04:39:35.153328+00	La mascota por nombre VICKY fue registrado con exito	1	\N
132	raza	1	2024-04-06 04:40:30.068228+00	La raza por nombre HUSKY SIBERIANO fue modificado con exito	2	\N
133	raza	2	2024-04-06 04:40:44.924598+00	La raza por nombre BULLDOG INGLÉS fue modificado con exito	2	\N
134	raza	3	2024-04-06 04:40:53.578497+00	La raza por nombre DÁLMATA fue modificado con exito	2	\N
135	raza	4	2024-04-06 04:41:02.705083+00	La raza por nombre SALCHICHA fue modificado con exito	2	\N
136	raza	5	2024-04-06 04:41:28.935261+00	La raza por nombre BÓXER fue modificado con exito	2	\N
137	raza	6	2024-04-06 04:41:37.105951+00	La raza por nombre PASTOR ALEMÁN fue modificado con exito	2	\N
138	raza	7	2024-04-06 04:41:43.81374+00	La raza por nombre POMERANIA fue modificado con exito	2	\N
139	raza	8	2024-04-06 04:41:51.455109+00	La raza por nombre POODLE fue modificado con exito	2	\N
140	raza	9	2024-04-06 04:41:56.947035+00	La raza por nombre PERSA fue modificado con exito	2	\N
141	raza	10	2024-04-06 04:42:03.436573+00	La raza por nombre SIAMÉS fue modificado con exito	2	\N
142	raza	11	2024-04-06 04:42:12.63322+00	La raza por nombre MAINE COON fue modificado con exito	2	\N
143	raza	12	2024-04-06 04:42:23.735931+00	La raza por nombre BENGALÍ fue modificado con exito	2	\N
144	raza	13	2024-04-06 04:42:40.0967+00	La raza por nombre SPHYNX fue modificado con exito	2	\N
145	raza	14	2024-04-06 04:42:46.848389+00	La raza por nombre EXÓTICO fue modificado con exito	2	\N
146	raza	15	2024-04-06 04:42:50.084543+00	La raza por nombre MESTIZO fue modificado con exito	2	\N
147	raza	16	2024-04-06 04:42:52.850367+00	La raza por nombre DESCONOCIDA fue modificado con exito	2	\N
148	usuario	1	2024-04-06 04:43:48.151009+00	El usuario glendy.geraldine sus datos fueron actualizados con exito	2	\N
149	usuario	2	2024-04-06 04:44:37.538867+00	El usuario miguel.becerra sus datos fueron actualizados con exito	2	\N
150	usuario	4	2024-04-06 04:45:27.901966+00	El usuario MIRANDAGIRON sus datos fueron actualizados con exito	2	\N
151	usuario	2	2024-04-06 04:46:54.180141+00	El usuario miguel.becerra sus datos fueron actualizados con exito	2	\N
152	cita	1	2024-04-07 00:15:59.29115+00	La cita fue programada con exito	1	\N
153	cita	1	2024-04-07 00:16:10.826585+00	La cita fue cancelada con exito	3	1
154	medicina	1	2024-04-07 00:16:47.100916+00	el medicamento por nombre PARACETAMOL fue registrado con exito	1	1
155	cita	2	2024-04-07 00:26:01.238752+00	La cita fue programada con exito	1	\N
156	cita	3	2024-04-07 00:31:16.536704+00	La cita fue programada con exito	1	\N
157	cita	3	2024-04-07 00:31:58.325409+00	La cita actualizada con exito	2	\N
158	cita	3	2024-04-07 00:32:50.350117+00	El estado de la cita fue cambiada con exito	3	\N
159	cita	3	2024-04-07 00:34:36.535662+00	La cita fue cancelada con exito	3	\N
160	cita	2	2024-04-07 00:35:44.413479+00	La cita fue cancelada con exito	3	3
161	cita	4	2024-04-07 00:40:56.294473+00	La cita fue programada con exito	1	\N
162	cita	4	2024-04-07 00:41:42.999115+00	La cita fue cancelada con exito	3	3
163	medicina	2	2024-04-07 01:11:11.077794+00	el medicamento por nombre Cetizina fue registrado con exito	1	3
164	medicina	3	2024-04-07 01:12:07.313296+00	el medicamento por nombre PREDNISONA fue registrado con exito	1	3
165	medicina	4	2024-04-07 01:12:30.727268+00	el medicamento por nombre C fue registrado con exito	1	3
166	medicina	5	2024-04-07 01:12:39.486235+00	el medicamento por nombre CICLOSPORINA fue registrado con exito	1	3
167	medicina	6	2024-04-07 01:13:06.811825+00	el medicamento por nombre BETAMETASONA fue registrado con exito	1	3
168	medicina	7	2024-04-07 01:13:32.763245+00	el medicamento por nombre DICLOFENACO fue registrado con exito	1	3
169	medicina	8	2024-04-07 01:14:54.676708+00	el medicamento por nombre CETIRIZINA fue registrado con exito	1	3
170	usuario	5	2024-04-07 01:43:51.536499+00	el usuario fue registrado con exito	1	\N
171	cliente	15	2024-04-07 01:43:51.704252+00	El cliente por nombre SOFIA fue registrado con exito	1	\N
172	mascota	10	2024-04-07 01:45:17.478936+00	La mascota por nombre LUNA fue registrado con exito	1	\N
173	cita	5	2024-04-07 01:45:57.592947+00	La cita fue programada con exito	1	\N
174	cita	5	2024-04-07 01:46:43.070212+00	La cita actualizada con exito	2	\N
175	cita	5	2024-04-07 01:47:06.710856+00	La cita actualizada con exito	2	\N
176	cita	5	2024-04-07 01:48:41.687176+00	La cita actualizada con exito	2	\N
177	cita	5	2024-04-07 01:49:10.936344+00	La cita actualizada con exito	2	\N
178	cita	5	2024-04-07 01:49:25.979352+00	La cita actualizada con exito	2	\N
179	cita	5	2024-04-07 01:50:29.535114+00	La cita actualizada con exito	2	\N
180	cita	1	2024-04-07 01:52:10.45423+00	La cita actualizada con exito	2	\N
182	cita	1	2024-04-07 01:56:43.704033+00	La cita actualizada con exito	2	\N
183	tipo_mascota	3	2024-04-07 04:09:50.210711+00	El tipo de mascota por nombre OTROS fue registrado con exito	1	\N
184	mascota	11	2024-04-07 05:13:21.805383+00	La mascota por nombre LUNA fue registrado con exito	1	\N
185	cita	6	2024-04-07 05:15:08.092941+00	La cita fue programada con exito	1	\N
186	cita	6	2024-04-07 05:18:05.889223+00	La cita fue cancelada con exito	3	3
187	medicina	9	2024-04-07 05:21:08.719014+00	el medicamento por nombre SHAMPOO KATAPULGUIN fue registrado con exito	1	3
188	usuario	6	2024-04-07 05:29:30.684837+00	el usuario fue registrado con exito	1	\N
189	cita	5	2024-04-07 05:30:08.875474+00	La cita fue cancelada con exito	3	6
190	mascota	12	2024-04-07 16:31:03.333882+00	La mascota por nombre LOBO fue registrado con exito	1	\N
191	cita	7	2024-04-07 16:32:09.107892+00	La cita fue programada con exito	1	\N
192	usuario	1	2024-04-19 22:45:30.800872+00	El usuario glendy.geraldine sus datos fueron actualizados con exito	2	\N
193	cita	8	2024-04-28 02:51:55.000826+00	La cita fue programada con exito	1	\N
194	cita	9	2024-04-28 02:53:14.568208+00	La cita fue programada con exito	1	\N
195	mascota	13	2024-04-28 02:54:42.100838+00	La mascota por nombre VICKY fue registrado con exito	1	\N
196	cita	10	2024-04-28 02:55:07.985704+00	La cita fue programada con exito	1	\N
197	cita	11	2024-04-28 02:56:28.252816+00	La cita fue programada con exito	1	\N
198	cita	12	2024-04-28 02:58:00.85136+00	La cita fue programada con exito	1	\N
199	cita	13	2024-05-09 05:28:16.170819+00	La cita fue programada con exito	1	\N
200	cita	14	2024-05-22 02:38:47.509668+00	La cita fue programada con exito	1	\N
201	cita	13	2024-05-22 03:03:56.770534+00	La cita fue cancelada con exito	3	1
202	cita	14	2024-05-22 03:06:26.739233+00	La cita fue cancelada con exito	3	1
203	cita	15	2024-05-22 03:22:13.220786+00	La cita fue programada con exito	1	\N
204	servicio	4	2024-06-06 02:55:19.021751+00	El servicio por nombre PERFIL RENAL SIMPLE COMPLETO fue modificado con exito	2	1
205	servicio	5	2024-06-06 02:56:19.399915+00	El servicio por nombre PERFIL HEPÁTICO COMPLETO fue modificado con exito	2	1
206	servicio	6	2024-06-06 02:56:53.30855+00	El servicio por nombre PERFIL LIPÍDICO fue modificado con exito	2	1
207	servicio	7	2024-06-06 02:57:34.692626+00	El servicio por nombre CONSULTA TRAUMATOLÓGICA fue modificado con exito	2	1
208	servicio	8	2024-06-06 02:58:04.699711+00	El servicio por nombre PROFILAXIS fue modificado con exito	2	1
209	cita	11	2024-06-06 03:12:37.045545+00	La cita fue cancelada con exito	3	3
210	pregunta_frecuente	5	2024-06-06 04:15:00.121017+00	El asunto por nombre ¿Cuáles son los requisitos o documentos necesarios para la cita? fue modificado con exito	2	1
211	pregunta_frecuente	1	2024-06-06 04:15:31.367503+00	Los datos fueron anulado con exito	3	1
212	pregunta_frecuente	7	2024-06-06 04:16:32.441217+00	Los datos fueron anulado con exito	3	1
213	pregunta_frecuente	3	2024-06-06 04:20:01.137333+00	Los datos fueron anulado con exito	3	1
214	usuario	1	2024-06-06 04:29:16.497492+00	El usuario glendy.geraldine sus datos fueron actualizados con exito	2	\N
215	usuario	1	2024-06-06 04:30:02.386994+00	El usuario glendy.geraldine sus datos fueron actualizados con exito	2	\N
216	usuario	1	2024-06-06 04:30:47.94299+00	Los datos fueron anulado con exito	3	\N
217	usuario	1	2024-06-06 04:30:54.598642+00	Los datos fueron restaurado con exito	6	\N
218	usuario	1	2024-06-06 04:31:17.178063+00	El usuario glendy.geraldine sus datos fueron actualizados con exito	2	\N
219	cita	16	2024-06-06 05:58:52.552764+00	La cita fue programada con exito	1	\N
220	cita	16	2024-06-06 05:59:09.214962+00	La cita fue cancelada con exito	3	3
221	usuario	7	2024-06-06 20:10:26.307163+00	el usuario fue registrado con exito	1	\N
222	cliente	16	2024-06-06 20:10:26.435736+00	El cliente por nombre JOSE fue registrado con exito	1	\N
223	usuario	1	2024-06-06 20:13:17.103832+00	El usuario glendy.geraldine sus datos fueron actualizados con exito	2	\N
224	usuario	1	2024-06-06 20:16:10.566857+00	El usuario glendy.geraldine sus datos fueron actualizados con exito	2	\N
225	usuario	1	2024-06-06 20:17:34.635051+00	El usuario glendy.geraldine sus datos fueron actualizados con exito	2	\N
226	mascota	14	2024-06-06 20:36:22.160253+00	La mascota por nombre LOLA fue registrado con exito	1	\N
227	cita	17	2024-06-06 20:36:54.079238+00	La cita fue programada con exito	1	\N
228	cita	18	2024-06-06 20:43:58.7484+00	La cita fue programada con exito	1	\N
229	cita	19	2024-06-06 20:45:57.456599+00	La cita fue programada con exito	1	\N
230	cita	17	2024-06-06 20:58:53.880912+00	La cita fue cancelada con exito	3	1
231	servicio	14	2024-06-08 22:18:08.171701+00	El servicio por nombre ECOGRAFIA GESTACIONAL fue modificado con exito	2	1
232	servicio	15	2024-06-08 22:18:19.568312+00	El servicio por nombre RASPADO CUTÁNEO fue modificado con exito	2	1
233	tipo_servicio	2	2024-06-08 22:22:59.164673+00	El tipo servicio fue anulado con exito	3	1
234	tipo_servicio	2	2024-06-08 22:23:04.82909+00	El tipo de servicio fue restaurado con exito	6	1
235	servicio	1	2024-06-12 06:32:32.146863+00	El servicio por nombre CONSULTA FELINA fue modificado con exito	2	1
236	usuario	1	2024-06-13 03:51:29.008034+00	El usuario glendy.geraldine sus datos fueron actualizados con exito	2	\N
\.


--
-- TOC entry 3735 (class 0 OID 16497)
-- Dependencies: 236
-- Data for Name: mascota; Type: TABLE DATA; Schema: public; Owner: djBackends
--

COPY public.mascota (id, nombre, fecha_nacimiento, sexo, color, fecha_registro, key_cliente_id, key_estado_id, key_raza_id, key_tipo_mascota_id) FROM stdin;
1	OSO	2023-12-09T03:13:00.000Z	Macho	#995900	2024-04-06 03:14:34.957346+00	3	1	6	1
2	ROCKY	2020-02-06T03:15:00.000Z	Macho	#9f9d9d	2024-04-06 03:16:38.356116+00	2	1	1	1
3	KAYSER	2024-03-15T03:16:00.000Z	Macho	#773f27	2024-04-06 03:17:50.054499+00	7	1	11	2
4	LOBO	2017-03-26T03:19:00.000Z	Macho	#121212	2024-04-06 03:20:11.87431+00	12	1	5	1
5	MININA	2023-04-01T03:35:00.000Z	Hembra	#d0bdbd	2024-04-06 03:35:50.117641+00	6	1	9	2
6	CARAMELO	2020-11-14T03:37:00.000Z	Macho	#d89d4b	2024-04-06 03:38:31.570777+00	11	1	4	1
7	BRONCO	2018-08-17T03:46:00.000Z	Macho	#b9770e	2024-04-06 03:46:44.889369+00	5	1	6	1
8	MIMI	2020-06-13T04:26:00.000Z	Hembra	#934d4d	2024-04-06 04:26:55.468221+00	14	1	12	2
9	VICKY	2023-11-11T04:39:00.000Z	Hembra	#926363	2024-04-06 04:39:35.139116+00	3	1	15	1
10	LUNA	2018-04-13T01:44:00.000Z	Hembra	#937b7b	2024-04-07 01:45:17.469441+00	15	1	12	2
11	LUNA	2020-04-10T05:12:00.000Z	Hembra	#aa9c97	2024-04-07 05:13:21.789666+00	2	1	9	2
12	LOBO	2021-02-11T16:30:00.000Z	Macho	#a73939	2024-04-07 16:31:03.292581+00	2	1	4	2
13	VICKY	2024-04-14T02:54:00.000Z	Macho	#ffffff	2024-04-28 02:54:42.09563+00	14	1	7	1
14	LOLA	2021-06-09T20:36:00.000Z	Hembra	\N	2024-06-06 20:36:22.113417+00	16	1	4	2
\.


--
-- TOC entry 3769 (class 0 OID 16963)
-- Dependencies: 270
-- Data for Name: medicina; Type: TABLE DATA; Schema: public; Owner: djBackends
--

COPY public.medicina (id, codigo, nombre, descripcion, key_estado_id) FROM stdin;
1	MED-001	PARACETAMOL	\N	1
2	MED-002	Cetizina	\N	1
3	MED-003	PREDNISONA	\N	1
4	MED-004	C	\N	1
5	MED-005	CICLOSPORINA	\N	1
6	MED-006	BETAMETASONA	\N	1
7	MED-007	DICLOFENACO	\N	1
8	MED-008	CETIRIZINA	\N	1
9	MED-009	SHAMPOO KATAPULGUIN	\N	1
\.


--
-- TOC entry 3757 (class 0 OID 16794)
-- Dependencies: 258
-- Data for Name: menu; Type: TABLE DATA; Schema: public; Owner: djBackends
--

COPY public.menu (id, menu, descripcion) FROM stdin;
1	Inicio	\N
2	Servicios	\N
3	Veterinarios	\N
4	Clientes	\N
5	Razas	\N
6	Mascotas	\N
7	Usuario	\N
8	citas	\N
9	Tipo-servicios	\N
10	Tipo-mascotas	\N
11	all	TODOS LOS MENUS, SE UTILIZA EL ALL PARA DEFINIR TODOS LOS PRIVILEGIOS 
\.


--
-- TOC entry 3767 (class 0 OID 16942)
-- Dependencies: 268
-- Data for Name: permiso; Type: TABLE DATA; Schema: public; Owner: djBackends
--

COPY public.permiso (id, permiso, fecha_registro, key_estado_id) FROM stdin;
2	manage	2024-04-04 00:00:00+00	1
3	menu	2024-04-04 00:00:00+00	1
4	create	2024-04-04 00:00:00+00	1
5	read	2024-04-04 00:00:00+00	1
6	update	2024-04-04 00:00:00+00	1
7	delete	2024-04-04 00:00:00+00	1
8	authorize	2024-04-04 00:00:00+00	1
\.


--
-- TOC entry 3755 (class 0 OID 16779)
-- Dependencies: 256
-- Data for Name: pregunta_frecuente; Type: TABLE DATA; Schema: public; Owner: djBackends
--

COPY public.pregunta_frecuente (id, asunto, descripcion, key_estado_id) FROM stdin;
8	¿Con cuánto tiempo de antelación debo reservar una cita?	La programación de citas se puede reservar en cualquier momento a través de la aplicación web, siempre y cuando la fecha y hora se encuentren disponibles.	1
4	¿Hay algún costo asociado con la cancelación de citas?	No, no hay ningún costo adicional ante la cancelación de una cita programada.	1
2	¿Cómo puedo cancelar o modificar mi cita una vez que la he reservado?	Para cancelación o reprogramación de cita, deberá seleccionar el módulo de Programación de citas, ubicar la fecha y hora de la cita que programó en el calendario y se mostrará los botones de Cancelar o Reprogramar cita, es ahí donde debe seleccionar lo que desee realizar.	1
6	¿Puedo ver mi historial de citas anteriores?	Sí, esta información se puede visualizar en el módulo Programación de citas, en la sección Mis Citas.	1
5	¿Cuáles son los requisitos o documentos necesarios para la cita?	Lo que deberá llevar en caso de tratamiento de la mascota será el carnet de vacunación.	1
1	¿Cuál es la modalidad de pago de los servicios?	Los pagos se pueden realizar únicamente de manera presencial en la Clínica Veterinaria Bamby Vet, ya sea en efectivo, o a través de medios virtuales como Yape y Plin.	2
7	¿Puedo solicitar una cita de emergencia?	En caso se trate de una cita de emergencia deberá de acerca presencialmente a la veterinaria para ser atendido priorizando su caso según la gravedad que considere el veterinario.	2
3	¿Cuál es el tiempo de duración de cada servicio?	Para conocer el tiempo aproximado de los servicios podrá visualizarlo en el módulo de Programación de citas, seleccionando el servicio por el cual desea consultar.	2
\.


--
-- TOC entry 3725 (class 0 OID 16434)
-- Dependencies: 226
-- Data for Name: raza; Type: TABLE DATA; Schema: public; Owner: djBackends
--

COPY public.raza (id, nombre_raza, descripcion, key_estado_id) FROM stdin;
1	HUSKY SIBERIANO	Conocido por su pelaje grueso y esponjoso, ojos azules o heterocromáticos. Tienen orejas erguidas y colas peludas que se curvan sobre la espalda.	1
2	BULLDOG INGLÉS	Con una cabeza grande y arrugada, mandíbulas anchas y cuerpo musculoso, el Bulldog Inglés es fácilmente reconocible. Tienen una nariz achatada y una mandíbula inferior prominente.	1
3	DÁLMATA	Con su pelaje blanco y manchas negras o marrones, el Dálmata es conocido por su apariencia distintiva. Tienen orejas caídas y una constitución atlética. Las manchas pueden variar en tamaño y forma.	1
4	SALCHICHA	Conocido por su cuerpo largo y bajo, el Dachshund tiene patas cortas y orejas caídas. Vienen en tres variedades de pelo: suave, largo y duro. Su cuerpo alargado se adapta bien a la caza de animales pequeños.	1
5	BÓXER	Con una cabeza cuadrada y mandíbulas poderosas, el Bóxer tiene una apariencia musculosa y robusta. Tienen orejas cortadas que se mantienen erguidas naturalmente y un pelaje corto y brillante.	1
6	PASTOR ALEMÁN	Reconocible por su pelaje doble, cabeza amplia y orejas erectas, el Pastor Alemán es una raza atlética y poderosa. Tienen una espalda recta y una cola larga. Son perros de trabajo versátiles y leales.	1
7	POMERANIA	Conocido por su pelaje denso y esponjoso, el Pomerania tiene una cabeza pequeña y orejas puntiagudas. A menudo tienen una cola esponjosa que se curva sobre la espalda. Son perros pequeños pero enérgicos.	1
8	POODLE	Conocido por su pelaje rizado o lanoso, el Poodle tiene una apariencia elegante y atlética. Vienen en tres tamaños: estándar, miniatura y toy. Tienen una cabeza refinada y orejas colgantes cubiertas de pelo rizado.	1
9	PERSA	Conocido por su pelaje largo y denso, el persa es un gato de aspecto majestuoso y tranquilo. Tiene una cara plana y ancha con grandes ojos redondos.	1
10	SIAMÉS	Reconocible por su pelaje corto y suave y sus ojos azules intensos, el siamés es una raza elegante y vocal. Son conocidos por ser afectuosos y sociables.	1
11	MAINE COON	Esta es una de las razas de gatos más grandes y robustas. Tienen pelaje largo y espeso, con un carácter amigable y gentil. Son excelentes cazadores y se dice que son muy inteligentes.	1
12	BENGALÍ	El bengalí es una raza exótica conocida por su pelaje similar al de un leopardo. Son activos, curiosos y juguetones, y a menudo disfrutan del agua.	1
13	SPHYNX	Esta es una raza única conocida por su falta de pelaje. A pesar de su apariencia inusual, los gatos sphynx son extremadamente cariñosos, juguetones y tienen una personalidad extrovertida.	1
14	EXÓTICO	Similar al persa pero con pelaje corto, el gato exótico es conocido por su dulce temperamento y su apariencia regordeta. Son tranquilos y cariñosos compañeros.	1
15	MESTIZO	Los perros mestizos son aquellos que provienen de la cruza de diferentes razas, lo que les confiere una variedad de características físicas y de personalidad.	1
16	DESCONOCIDA	Se desconoce la raza de la mascota	1
\.


--
-- TOC entry 3773 (class 0 OID 16981)
-- Dependencies: 274
-- Data for Name: receta; Type: TABLE DATA; Schema: public; Owner: djBackends
--

COPY public.receta (id, fecha_creacion, key_cita_id) FROM stdin;
1	2024-04-07 00:39:00.204051+00	2
2	2024-04-07 01:27:03.260307+00	4
3	2024-04-07 05:22:13.195262+00	6
4	2024-04-07 05:34:34.553908+00	5
5	2024-05-22 03:04:15.045629+00	13
6	2024-05-22 03:06:30.10301+00	14
7	2024-06-06 06:01:26.186189+00	16
8	2024-06-06 20:59:27.47262+00	17
\.


--
-- TOC entry 3778 (class 0 OID 49154)
-- Dependencies: 279
-- Data for Name: restablecer_usuario; Type: TABLE DATA; Schema: public; Owner: djBackends
--

COPY public.restablecer_usuario (id, toke, fecha_creacion, expired, codigo_recuperacion, is_activo, key_usuario_id) FROM stdin;
1	jAL8oXcg59tiIQWgupiBpLYcgVOq9fFl	2024-06-06 20:11:12.277232+00	2024-06-07 20:11:12.272667+00	DQHYHU	f	1
2	mvDV0lScRwXaDxRs4NQo3MYrP1vrKbkr	2024-06-06 20:13:47.654271+00	2024-06-07 20:13:47.645709+00	PE97HB	f	1
3	b807i6d89HznslGPRghQohaen1USmGEI	2024-06-06 20:16:31.166578+00	2024-06-07 20:16:31.156154+00	OXZN25	f	1
4	YVXUAps7UIkhJ8DUGPRK3nxps57Yf3EQ	2024-06-06 20:17:57.678156+00	2024-06-07 20:17:57.66351+00	225IHY	f	1
5	RoloMpQXFmcxTEZFR9lMmPRy4dRP4eV3	2024-06-12 06:11:46.86341+00	2024-06-13 06:11:46.780151+00	E7HKHZ	f	1
6	Xe63WlOdE2Mwv3flhCcKv6ovBoIopo3c	2024-06-12 06:12:09.214861+00	2024-06-13 06:12:09.2017+00	Z98FYV	t	1
\.


--
-- TOC entry 3727 (class 0 OID 16443)
-- Dependencies: 228
-- Data for Name: servicio; Type: TABLE DATA; Schema: public; Owner: djBackends
--

COPY public.servicio (id, nombre_servicio, descripcion, precio, key_estado_id, key_tipo_servicio_id, duracion) FROM stdin;
2	CONSULTA CANINA		75	1	7	30
3	CONSULTA DERMATOLÓGICA		45	1	7	45
9	BAÑO MEDICADO		60	1	5	45
10	BAÑO ESTÉTICO		50	1	5	60
11	CORTE HIGIENICO		45	1	5	45
12	CORTE ESTÉTICO		45	1	5	45
13	ECOGRAFIA ABDOMINAL		60	1	6	45
4	PERFIL RENAL SIMPLE COMPLETO	Conjunto de pruebas de laboratorio que evalúa la función renal mediante la medición de parámetros como creatinina, urea, electrolitos y fósforo en sangre, así como un análisis de orina, entre otras.	80	1	1	60
5	PERFIL HEPÁTICO COMPLETO	Evalúa la función del hígado mediante la medición de enzimas y biomarcadores en sangre, permitiendo la detección temprana y el tratamiento de enfermedades hepáticas.	60	1	1	60
6	PERFIL LIPÍDICO	Evalúa los niveles de grasas en la sangre, como colesterol y triglicéridos, para detectar y manejar problemas cardiovasculares y pancreatitis.	35	1	1	45
7	CONSULTA TRAUMATOLÓGICA	Aborda lesiones musculoesqueléticas como fracturas o luxaciones, con el objetivo de diagnosticar y tratar adecuadamente, ya sea con reposo, medicación o cirugía, para facilitar la recuperación y restaurar la funcionalidad.	65	1	7	30
8	PROFILAXIS	Se refiere a medidas preventivas que ayudan a mantener su salud y prevenir enfermedades. Esto puede incluir vacunaciones regulares, desparasitación, cuidado dental, alimentación balanceada y ejercicio adecuado.	50	1	4	45
14	ECOGRAFIA GESTACIONAL		65	1	6	45
15	RASPADO CUTÁNEO		80	1	4	60
1	CONSULTA FELINA	m	75	1	7	30
\.


--
-- TOC entry 3753 (class 0 OID 16750)
-- Dependencies: 254
-- Data for Name: tipo_cita; Type: TABLE DATA; Schema: public; Owner: djBackends
--

COPY public.tipo_cita (id, tipo_cita, descripcion, key_estado_id) FROM stdin;
1	PRIMERA CITA	\N	1
2	VISITA CONTROL	\N	1
\.


--
-- TOC entry 3729 (class 0 OID 16452)
-- Dependencies: 230
-- Data for Name: tipo_estado; Type: TABLE DATA; Schema: public; Owner: djBackends
--

COPY public.tipo_estado (id, nombre, descripcion) FROM stdin;
1	ELIMINACION LOGICA	\N
2	ELIMINACION FISICA	\N
3	ESTADO GENERAL	\N
4	ESTADOS DE LA CITA	\N
\.


--
-- TOC entry 3751 (class 0 OID 16729)
-- Dependencies: 252
-- Data for Name: tipo_mascota; Type: TABLE DATA; Schema: public; Owner: djBackends
--

COPY public.tipo_mascota (id, tipo, descripcion, key_estado_id) FROM stdin;
2	GATO		1
1	PERRO		1
3	OTROS		1
\.


--
-- TOC entry 3749 (class 0 OID 16695)
-- Dependencies: 250
-- Data for Name: tipo_servicio; Type: TABLE DATA; Schema: public; Owner: djBackends
--

COPY public.tipo_servicio (id, tipo_servicio, descripcion, key_estado_id) FROM stdin;
3	Exámenes Bioquímicos		1
4	Otros		1
5	SPA		1
6	Ecografías		1
7	Consulta general		1
1	Laboratorio - Perfiles		1
2	Exámenes Especiales		1
\.


--
-- TOC entry 3731 (class 0 OID 16461)
-- Dependencies: 232
-- Data for Name: tipo_usuario; Type: TABLE DATA; Schema: public; Owner: djBackends
--

COPY public.tipo_usuario (id, tipo_usuario, descripcion, action) FROM stdin;
1	ADMINISTRADOR	PERSONAL QUE RELIZA MANTENIMIENTO AL SISTEMA 	manage
2	VETERINARIO	PERSONAL QUE ATIENDE AL CLIENTE 	read
3	CLIENTE	PERSONAL QUE SOLICITA LAS ATENCIONES	read
\.


--
-- TOC entry 3771 (class 0 OID 16972)
-- Dependencies: 272
-- Data for Name: triaje; Type: TABLE DATA; Schema: public; Owner: djBackends
--

COPY public.triaje (id, peso, temperatura, frecuencia_cardica, frecuencia_respiratoria, key_cita_id) FROM stdin;
1					2
2	10	36	120	20	4
3	15	36	80	30	6
4	16	110	80	20	5
5					13
6					14
7	13	35	80	25	16
8					17
\.


--
-- TOC entry 3761 (class 0 OID 16840)
-- Dependencies: 262
-- Data for Name: usuario; Type: TABLE DATA; Schema: public; Owner: djBackends
--

COPY public.usuario (id, password, last_login, is_superuser, username, first_name, last_name, email, is_staff, is_active, date_joined, document_number, user_type_id, status_id) FROM stdin;
1	pbkdf2_sha256$320000$FKfJ3HoxDYadgVDf9DSsDK$dJKbfhKJZRMFfPqeLfe4Kj9/EgNmJ8xfau/Kk1Ofsds=	2024-06-14 04:36:19.088862+00	f	glendy.geraldine	GLENDY GERALDINE	TORRES JUAREZ	ggtorres@ucvvirtual.edu.pe	f	t	2024-04-04 21:16:41.342405+00	74773765	1	1
6	pbkdf2_sha256$320000$K4i18WOaQwUPZFYLgsM7dj$bdbbQXylT9QVKLT3IFD92GhgEoWVv3hVU3+O+1H9Kpk=	2024-05-22 02:34:25.443265+00	f	maricielocast	MARICIELO	CASTILLO MELENDEZ	MARICIELOCASTILLO@GMAIL.COM	f	t	2024-04-07 05:29:30.650683+00	75167028	2	1
5	pbkdf2_sha256$320000$K3GIQX3fzaT7kR5OaKb2UF$JCWEPktOmih6Xc3dF7c4r8nt1zD/Ta16sTuDtBQPT1U=	2024-05-22 03:06:52.592819+00	f	sofiamontes	SOFIA	MONTES CARREÑO	SOFIMONTE@GMAIL.COM	f	t	2024-04-07 01:43:51.481613+00	74526358	3	1
3	pbkdf2_sha256$320000$X9i0psGU4Ki7N0qKu69J1H$jADeqKdXMzOlTs0TKJNCWwmDKEdMoXB06ygmvZV/tsY=	2024-06-08 01:08:36.0184+00	f	alexanderjc	JOSE ALEXANDER	JIMENEZ CORONEL	alexanderveter@gmail.com	f	t	2024-04-04 23:12:38.339486+00	42006478	2	1
4	pbkdf2_sha256$320000$SCXBa0vZdQyjlEZUebTxxy$dC8+HJWXEKlnRvDwRAUW4574PiXVqK3QAbaqaqfNsmY=	2024-04-06 04:24:46.683571+00	f	MIRANDAGIRON	MIRANDA	GIRON	MIRANDA@GMAIL.COM	f	t	2024-04-06 04:24:39.044525+00	02785152	3	1
7	pbkdf2_sha256$320000$du6QslFLvGd3jsjzCzhDRB$GtnF8LnQYka9Yps/+Ty6WIqf3Yz9OTBV9M//gU8zfag=	2024-06-08 01:08:53.733179+00	f	josecampos	JOSE	CAMPOS SOSA	josecamp@gmail.com	f	t	2024-06-06 20:10:26.272126+00	02569475	3	1
2	pbkdf2_sha256$320000$uF81afqdaxztd08j3dPsJS$/RwE7ZkPLM8dbR20+s4RA1oQE+RbzxWOojJV2DEndv0=	2024-06-08 01:09:11.048906+00	f	miguel.becerra	MIGUEL IVAN	BECERRA GUERRERO	miguelbec@gmail.com	f	t	2024-04-04 21:43:05.537439+00	72020362	3	1
\.


--
-- TOC entry 3763 (class 0 OID 16853)
-- Dependencies: 264
-- Data for Name: usuario_groups; Type: TABLE DATA; Schema: public; Owner: djBackends
--

COPY public.usuario_groups (id, usuario_id, group_id) FROM stdin;
\.


--
-- TOC entry 3765 (class 0 OID 16867)
-- Dependencies: 266
-- Data for Name: usuario_user_permissions; Type: TABLE DATA; Schema: public; Owner: djBackends
--

COPY public.usuario_user_permissions (id, usuario_id, permission_id) FROM stdin;
\.


--
-- TOC entry 3733 (class 0 OID 16470)
-- Dependencies: 234
-- Data for Name: veterinario; Type: TABLE DATA; Schema: public; Owner: djBackends
--

COPY public.veterinario (id, nombre, apellido, direccion, correo, fecha_registro, num_cel, key_estado_id, dni, sexo) FROM stdin;
1	JOSE ALEXANDER	JIMENEZ CORONEL	Av. Champanat 458 Sullana	alexanderveter2220@gmail.com	2024-04-04 22:34:49.394505+00	979171172	1	42006478	Masculino
2	BRONIA INDIRA	VALDIVIESO PALACIOS	Calle Apurímac 265 Sullana	broniaveter@gmail.com	2024-04-04 22:39:35.09678+00	986423586	1	44247118	Femenino
4	MARIA LOURDES	CACERES CAMPOS	Calle Catacaos 321	mariacaceresveter@gmail.com	2024-04-04 22:42:46.733547+00	956234879	1	40958260	Femenino
3	MARICIELO	CASTILLO MELENDEZ	Calle Bernal 245	maricastveter@gmail.com	2024-04-04 22:40:38.528892+00	965423856	1	75167028	Femenino
\.


--
-- TOC entry 3816 (class 0 OID 0)
-- Dependencies: 275
-- Name: app_veterinaria_detalle_receta_id_seq; Type: SEQUENCE SET; Schema: public; Owner: djBackends
--

SELECT pg_catalog.setval('public.app_veterinaria_detalle_receta_id_seq', 5, true);


--
-- TOC entry 3817 (class 0 OID 0)
-- Dependencies: 267
-- Name: app_veterinaria_permiso_id_seq; Type: SEQUENCE SET; Schema: public; Owner: djBackends
--

SELECT pg_catalog.setval('public.app_veterinaria_permiso_id_seq', 4, true);


--
-- TOC entry 3818 (class 0 OID 0)
-- Dependencies: 259
-- Name: asignacion_permiso_id_seq; Type: SEQUENCE SET; Schema: public; Owner: djBackends
--

SELECT pg_catalog.setval('public.asignacion_permiso_id_seq', 5, true);


--
-- TOC entry 3819 (class 0 OID 0)
-- Dependencies: 245
-- Name: auth_group_id_seq; Type: SEQUENCE SET; Schema: public; Owner: djBackends
--

SELECT pg_catalog.setval('public.auth_group_id_seq', 1, false);


--
-- TOC entry 3820 (class 0 OID 0)
-- Dependencies: 247
-- Name: auth_group_permissions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: djBackends
--

SELECT pg_catalog.setval('public.auth_group_permissions_id_seq', 1, false);


--
-- TOC entry 3821 (class 0 OID 0)
-- Dependencies: 243
-- Name: auth_permission_id_seq; Type: SEQUENCE SET; Schema: public; Owner: djBackends
--

SELECT pg_catalog.setval('public.auth_permission_id_seq', 116, true);


--
-- TOC entry 3822 (class 0 OID 0)
-- Dependencies: 239
-- Name: cita_id_seq; Type: SEQUENCE SET; Schema: public; Owner: djBackends
--

SELECT pg_catalog.setval('public.cita_id_seq', 19, true);


--
-- TOC entry 3823 (class 0 OID 0)
-- Dependencies: 219
-- Name: cliente_id_seq; Type: SEQUENCE SET; Schema: public; Owner: djBackends
--

SELECT pg_catalog.setval('public.cliente_id_seq', 16, true);


--
-- TOC entry 3824 (class 0 OID 0)
-- Dependencies: 241
-- Name: django_admin_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: djBackends
--

SELECT pg_catalog.setval('public.django_admin_log_id_seq', 1, false);


--
-- TOC entry 3825 (class 0 OID 0)
-- Dependencies: 217
-- Name: django_content_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: djBackends
--

SELECT pg_catalog.setval('public.django_content_type_id_seq', 29, true);


--
-- TOC entry 3826 (class 0 OID 0)
-- Dependencies: 215
-- Name: django_migrations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: djBackends
--

SELECT pg_catalog.setval('public.django_migrations_id_seq', 60, true);


--
-- TOC entry 3827 (class 0 OID 0)
-- Dependencies: 221
-- Name: estado_id_seq; Type: SEQUENCE SET; Schema: public; Owner: djBackends
--

SELECT pg_catalog.setval('public.estado_id_seq', 1, false);


--
-- TOC entry 3828 (class 0 OID 0)
-- Dependencies: 223
-- Name: evento_id_seq; Type: SEQUENCE SET; Schema: public; Owner: djBackends
--

SELECT pg_catalog.setval('public.evento_id_seq', 6, true);


--
-- TOC entry 3829 (class 0 OID 0)
-- Dependencies: 237
-- Name: log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: djBackends
--

SELECT pg_catalog.setval('public.log_id_seq', 236, true);


--
-- TOC entry 3830 (class 0 OID 0)
-- Dependencies: 235
-- Name: mascota_id_seq; Type: SEQUENCE SET; Schema: public; Owner: djBackends
--

SELECT pg_catalog.setval('public.mascota_id_seq', 14, true);


--
-- TOC entry 3831 (class 0 OID 0)
-- Dependencies: 269
-- Name: medicina_id_seq; Type: SEQUENCE SET; Schema: public; Owner: djBackends
--

SELECT pg_catalog.setval('public.medicina_id_seq', 9, true);


--
-- TOC entry 3832 (class 0 OID 0)
-- Dependencies: 257
-- Name: menu_id_seq; Type: SEQUENCE SET; Schema: public; Owner: djBackends
--

SELECT pg_catalog.setval('public.menu_id_seq', 11, true);


--
-- TOC entry 3833 (class 0 OID 0)
-- Dependencies: 255
-- Name: pregunta_frecuente_id_seq; Type: SEQUENCE SET; Schema: public; Owner: djBackends
--

SELECT pg_catalog.setval('public.pregunta_frecuente_id_seq', 8, true);


--
-- TOC entry 3834 (class 0 OID 0)
-- Dependencies: 225
-- Name: raza_id_seq; Type: SEQUENCE SET; Schema: public; Owner: djBackends
--

SELECT pg_catalog.setval('public.raza_id_seq', 16, true);


--
-- TOC entry 3835 (class 0 OID 0)
-- Dependencies: 273
-- Name: receta_id_seq; Type: SEQUENCE SET; Schema: public; Owner: djBackends
--

SELECT pg_catalog.setval('public.receta_id_seq', 8, true);


--
-- TOC entry 3836 (class 0 OID 0)
-- Dependencies: 278
-- Name: restablecer_usuario_id_seq; Type: SEQUENCE SET; Schema: public; Owner: djBackends
--

SELECT pg_catalog.setval('public.restablecer_usuario_id_seq', 6, true);


--
-- TOC entry 3837 (class 0 OID 0)
-- Dependencies: 227
-- Name: servicio_id_seq; Type: SEQUENCE SET; Schema: public; Owner: djBackends
--

SELECT pg_catalog.setval('public.servicio_id_seq', 15, true);


--
-- TOC entry 3838 (class 0 OID 0)
-- Dependencies: 253
-- Name: tipo_cita_id_seq; Type: SEQUENCE SET; Schema: public; Owner: djBackends
--

SELECT pg_catalog.setval('public.tipo_cita_id_seq', 2, true);


--
-- TOC entry 3839 (class 0 OID 0)
-- Dependencies: 229
-- Name: tipo_estado_id_seq; Type: SEQUENCE SET; Schema: public; Owner: djBackends
--

SELECT pg_catalog.setval('public.tipo_estado_id_seq', 4, true);


--
-- TOC entry 3840 (class 0 OID 0)
-- Dependencies: 251
-- Name: tipo_mascota_id_seq; Type: SEQUENCE SET; Schema: public; Owner: djBackends
--

SELECT pg_catalog.setval('public.tipo_mascota_id_seq', 3, true);


--
-- TOC entry 3841 (class 0 OID 0)
-- Dependencies: 249
-- Name: tipo_servicio_id_seq; Type: SEQUENCE SET; Schema: public; Owner: djBackends
--

SELECT pg_catalog.setval('public.tipo_servicio_id_seq', 7, true);


--
-- TOC entry 3842 (class 0 OID 0)
-- Dependencies: 231
-- Name: tipo_usuario_id_seq; Type: SEQUENCE SET; Schema: public; Owner: djBackends
--

SELECT pg_catalog.setval('public.tipo_usuario_id_seq', 3, true);


--
-- TOC entry 3843 (class 0 OID 0)
-- Dependencies: 271
-- Name: triaje_id_seq; Type: SEQUENCE SET; Schema: public; Owner: djBackends
--

SELECT pg_catalog.setval('public.triaje_id_seq', 8, true);


--
-- TOC entry 3844 (class 0 OID 0)
-- Dependencies: 263
-- Name: usuario_groups_id_seq; Type: SEQUENCE SET; Schema: public; Owner: djBackends
--

SELECT pg_catalog.setval('public.usuario_groups_id_seq', 1, false);


--
-- TOC entry 3845 (class 0 OID 0)
-- Dependencies: 261
-- Name: usuario_id_seq; Type: SEQUENCE SET; Schema: public; Owner: djBackends
--

SELECT pg_catalog.setval('public.usuario_id_seq', 7, true);


--
-- TOC entry 3846 (class 0 OID 0)
-- Dependencies: 265
-- Name: usuario_user_permissions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: djBackends
--

SELECT pg_catalog.setval('public.usuario_user_permissions_id_seq', 1, false);


--
-- TOC entry 3847 (class 0 OID 0)
-- Dependencies: 233
-- Name: veterinario_id_seq; Type: SEQUENCE SET; Schema: public; Owner: djBackends
--

SELECT pg_catalog.setval('public.veterinario_id_seq', 4, true);


--
-- TOC entry 3521 (class 2606 OID 17021)
-- Name: detalle_receta app_veterinaria_detalle_receta_pkey; Type: CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.detalle_receta
    ADD CONSTRAINT app_veterinaria_detalle_receta_pkey PRIMARY KEY (id);


--
-- TOC entry 3508 (class 2606 OID 16949)
-- Name: permiso app_veterinaria_permiso_pkey; Type: CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.permiso
    ADD CONSTRAINT app_veterinaria_permiso_pkey PRIMARY KEY (id);


--
-- TOC entry 3483 (class 2606 OID 16808)
-- Name: asignacion_permiso asignacion_permiso_pkey; Type: CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.asignacion_permiso
    ADD CONSTRAINT asignacion_permiso_pkey PRIMARY KEY (id);


--
-- TOC entry 3456 (class 2606 OID 16686)
-- Name: auth_group auth_group_name_key; Type: CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.auth_group
    ADD CONSTRAINT auth_group_name_key UNIQUE (name);


--
-- TOC entry 3461 (class 2606 OID 16672)
-- Name: auth_group_permissions auth_group_permissions_group_id_permission_id_0cd325b0_uniq; Type: CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.auth_group_permissions
    ADD CONSTRAINT auth_group_permissions_group_id_permission_id_0cd325b0_uniq UNIQUE (group_id, permission_id);


--
-- TOC entry 3464 (class 2606 OID 16661)
-- Name: auth_group_permissions auth_group_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.auth_group_permissions
    ADD CONSTRAINT auth_group_permissions_pkey PRIMARY KEY (id);


--
-- TOC entry 3458 (class 2606 OID 16652)
-- Name: auth_group auth_group_pkey; Type: CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.auth_group
    ADD CONSTRAINT auth_group_pkey PRIMARY KEY (id);


--
-- TOC entry 3451 (class 2606 OID 16663)
-- Name: auth_permission auth_permission_content_type_id_codename_01ab375a_uniq; Type: CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.auth_permission
    ADD CONSTRAINT auth_permission_content_type_id_codename_01ab375a_uniq UNIQUE (content_type_id, codename);


--
-- TOC entry 3453 (class 2606 OID 16645)
-- Name: auth_permission auth_permission_pkey; Type: CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.auth_permission
    ADD CONSTRAINT auth_permission_pkey PRIMARY KEY (id);


--
-- TOC entry 3444 (class 2606 OID 16530)
-- Name: cita cita_pkey; Type: CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.cita
    ADD CONSTRAINT cita_pkey PRIMARY KEY (id);


--
-- TOC entry 3407 (class 2606 OID 16414)
-- Name: cliente cliente_pkey; Type: CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.cliente
    ADD CONSTRAINT cliente_pkey PRIMARY KEY (id);


--
-- TOC entry 3447 (class 2606 OID 16626)
-- Name: django_admin_log django_admin_log_pkey; Type: CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.django_admin_log
    ADD CONSTRAINT django_admin_log_pkey PRIMARY KEY (id);


--
-- TOC entry 3402 (class 2606 OID 16405)
-- Name: django_content_type django_content_type_app_label_model_76bd3d3b_uniq; Type: CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.django_content_type
    ADD CONSTRAINT django_content_type_app_label_model_76bd3d3b_uniq UNIQUE (app_label, model);


--
-- TOC entry 3404 (class 2606 OID 16403)
-- Name: django_content_type django_content_type_pkey; Type: CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.django_content_type
    ADD CONSTRAINT django_content_type_pkey PRIMARY KEY (id);


--
-- TOC entry 3400 (class 2606 OID 16396)
-- Name: django_migrations django_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.django_migrations
    ADD CONSTRAINT django_migrations_pkey PRIMARY KEY (id);


--
-- TOC entry 3524 (class 2606 OID 17040)
-- Name: django_session django_session_pkey; Type: CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.django_session
    ADD CONSTRAINT django_session_pkey PRIMARY KEY (session_key);


--
-- TOC entry 3410 (class 2606 OID 16423)
-- Name: estado estado_pkey; Type: CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.estado
    ADD CONSTRAINT estado_pkey PRIMARY KEY (id);


--
-- TOC entry 3412 (class 2606 OID 16432)
-- Name: evento evento_pkey; Type: CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.evento
    ADD CONSTRAINT evento_pkey PRIMARY KEY (id);


--
-- TOC entry 3436 (class 2606 OID 16513)
-- Name: log log_pkey; Type: CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.log
    ADD CONSTRAINT log_pkey PRIMARY KEY (id);


--
-- TOC entry 3432 (class 2606 OID 16504)
-- Name: mascota mascota_pkey; Type: CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.mascota
    ADD CONSTRAINT mascota_pkey PRIMARY KEY (id);


--
-- TOC entry 3511 (class 2606 OID 16970)
-- Name: medicina medicina_pkey; Type: CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.medicina
    ADD CONSTRAINT medicina_pkey PRIMARY KEY (id);


--
-- TOC entry 3478 (class 2606 OID 16801)
-- Name: menu menu_pkey; Type: CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.menu
    ADD CONSTRAINT menu_pkey PRIMARY KEY (id);


--
-- TOC entry 3476 (class 2606 OID 16786)
-- Name: pregunta_frecuente pregunta_frecuente_pkey; Type: CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.pregunta_frecuente
    ADD CONSTRAINT pregunta_frecuente_pkey PRIMARY KEY (id);


--
-- TOC entry 3415 (class 2606 OID 16441)
-- Name: raza raza_pkey; Type: CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.raza
    ADD CONSTRAINT raza_pkey PRIMARY KEY (id);


--
-- TOC entry 3517 (class 2606 OID 16988)
-- Name: receta receta_pkey; Type: CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.receta
    ADD CONSTRAINT receta_pkey PRIMARY KEY (id);


--
-- TOC entry 3528 (class 2606 OID 49161)
-- Name: restablecer_usuario restablecer_usuario_pkey; Type: CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.restablecer_usuario
    ADD CONSTRAINT restablecer_usuario_pkey PRIMARY KEY (id);


--
-- TOC entry 3419 (class 2606 OID 16450)
-- Name: servicio servicio_pkey; Type: CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.servicio
    ADD CONSTRAINT servicio_pkey PRIMARY KEY (id);


--
-- TOC entry 3473 (class 2606 OID 16757)
-- Name: tipo_cita tipo_cita_pkey; Type: CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.tipo_cita
    ADD CONSTRAINT tipo_cita_pkey PRIMARY KEY (id);


--
-- TOC entry 3421 (class 2606 OID 16459)
-- Name: tipo_estado tipo_estado_pkey; Type: CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.tipo_estado
    ADD CONSTRAINT tipo_estado_pkey PRIMARY KEY (id);


--
-- TOC entry 3470 (class 2606 OID 16736)
-- Name: tipo_mascota tipo_mascota_pkey; Type: CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.tipo_mascota
    ADD CONSTRAINT tipo_mascota_pkey PRIMARY KEY (id);


--
-- TOC entry 3467 (class 2606 OID 16702)
-- Name: tipo_servicio tipo_servicio_pkey; Type: CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.tipo_servicio
    ADD CONSTRAINT tipo_servicio_pkey PRIMARY KEY (id);


--
-- TOC entry 3423 (class 2606 OID 16468)
-- Name: tipo_usuario tipo_usuario_pkey; Type: CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.tipo_usuario
    ADD CONSTRAINT tipo_usuario_pkey PRIMARY KEY (id);


--
-- TOC entry 3514 (class 2606 OID 16979)
-- Name: triaje triaje_pkey; Type: CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.triaje
    ADD CONSTRAINT triaje_pkey PRIMARY KEY (id);


--
-- TOC entry 3496 (class 2606 OID 16858)
-- Name: usuario_groups usuario_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.usuario_groups
    ADD CONSTRAINT usuario_groups_pkey PRIMARY KEY (id);


--
-- TOC entry 3499 (class 2606 OID 16881)
-- Name: usuario_groups usuario_groups_usuario_id_group_id_2e3cd638_uniq; Type: CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.usuario_groups
    ADD CONSTRAINT usuario_groups_usuario_id_group_id_2e3cd638_uniq UNIQUE (usuario_id, group_id);


--
-- TOC entry 3486 (class 2606 OID 16851)
-- Name: usuario usuario_num_documento_key; Type: CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_num_documento_key UNIQUE (document_number);


--
-- TOC entry 3488 (class 2606 OID 16847)
-- Name: usuario usuario_pkey; Type: CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_pkey PRIMARY KEY (id);


--
-- TOC entry 3502 (class 2606 OID 16872)
-- Name: usuario_user_permissions usuario_user_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.usuario_user_permissions
    ADD CONSTRAINT usuario_user_permissions_pkey PRIMARY KEY (id);


--
-- TOC entry 3505 (class 2606 OID 16909)
-- Name: usuario_user_permissions usuario_user_permissions_usuario_id_permission_id_3db58b8c_uniq; Type: CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.usuario_user_permissions
    ADD CONSTRAINT usuario_user_permissions_usuario_id_permission_id_3db58b8c_uniq UNIQUE (usuario_id, permission_id);


--
-- TOC entry 3493 (class 2606 OID 16849)
-- Name: usuario usuario_username_key; Type: CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_username_key UNIQUE (username);


--
-- TOC entry 3426 (class 2606 OID 16477)
-- Name: veterinario veterinario_pkey; Type: CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.veterinario
    ADD CONSTRAINT veterinario_pkey PRIMARY KEY (id);


--
-- TOC entry 3518 (class 1259 OID 17032)
-- Name: app_veterinaria_detalle_receta_key_medicamento_id_30cc9e92; Type: INDEX; Schema: public; Owner: djBackends
--

CREATE INDEX app_veterinaria_detalle_receta_key_medicamento_id_30cc9e92 ON public.detalle_receta USING btree (key_medicamento_id);


--
-- TOC entry 3519 (class 1259 OID 17033)
-- Name: app_veterinaria_detalle_receta_key_receta_id_a1069b76; Type: INDEX; Schema: public; Owner: djBackends
--

CREATE INDEX app_veterinaria_detalle_receta_key_receta_id_a1069b76 ON public.detalle_receta USING btree (key_receta_id);


--
-- TOC entry 3506 (class 1259 OID 16960)
-- Name: app_veterinaria_permiso_key_estado_id_6f1d860a; Type: INDEX; Schema: public; Owner: djBackends
--

CREATE INDEX app_veterinaria_permiso_key_estado_id_6f1d860a ON public.permiso USING btree (key_estado_id);


--
-- TOC entry 3479 (class 1259 OID 16819)
-- Name: asignacion_permiso_key_menu_id_96681a91; Type: INDEX; Schema: public; Owner: djBackends
--

CREATE INDEX asignacion_permiso_key_menu_id_96681a91 ON public.asignacion_permiso USING btree (key_menu_id);


--
-- TOC entry 3480 (class 1259 OID 16961)
-- Name: asignacion_permiso_key_permiso_id_e599b6ac; Type: INDEX; Schema: public; Owner: djBackends
--

CREATE INDEX asignacion_permiso_key_permiso_id_e599b6ac ON public.asignacion_permiso USING btree (key_permiso_id);


--
-- TOC entry 3481 (class 1259 OID 16835)
-- Name: asignacion_permiso_key_tipo_usuario_id_8f4c6a7b; Type: INDEX; Schema: public; Owner: djBackends
--

CREATE INDEX asignacion_permiso_key_tipo_usuario_id_8f4c6a7b ON public.asignacion_permiso USING btree (key_tipo_usuario_id);


--
-- TOC entry 3454 (class 1259 OID 16687)
-- Name: auth_group_name_a6ea08ec_like; Type: INDEX; Schema: public; Owner: djBackends
--

CREATE INDEX auth_group_name_a6ea08ec_like ON public.auth_group USING btree (name varchar_pattern_ops);


--
-- TOC entry 3459 (class 1259 OID 16683)
-- Name: auth_group_permissions_group_id_b120cbf9; Type: INDEX; Schema: public; Owner: djBackends
--

CREATE INDEX auth_group_permissions_group_id_b120cbf9 ON public.auth_group_permissions USING btree (group_id);


--
-- TOC entry 3462 (class 1259 OID 16684)
-- Name: auth_group_permissions_permission_id_84c5c92e; Type: INDEX; Schema: public; Owner: djBackends
--

CREATE INDEX auth_group_permissions_permission_id_84c5c92e ON public.auth_group_permissions USING btree (permission_id);


--
-- TOC entry 3449 (class 1259 OID 16669)
-- Name: auth_permission_content_type_id_2f476e4b; Type: INDEX; Schema: public; Owner: djBackends
--

CREATE INDEX auth_permission_content_type_id_2f476e4b ON public.auth_permission USING btree (content_type_id);


--
-- TOC entry 3437 (class 1259 OID 16613)
-- Name: cita_key_cliente_id_e7c6d0d6; Type: INDEX; Schema: public; Owner: djBackends
--

CREATE INDEX cita_key_cliente_id_e7c6d0d6 ON public.cita USING btree (key_cliente_id);


--
-- TOC entry 3438 (class 1259 OID 16614)
-- Name: cita_key_estado_id_3d3aea8a; Type: INDEX; Schema: public; Owner: djBackends
--

CREATE INDEX cita_key_estado_id_3d3aea8a ON public.cita USING btree (key_estado_id);


--
-- TOC entry 3439 (class 1259 OID 16615)
-- Name: cita_key_mascota_id_b08a436e; Type: INDEX; Schema: public; Owner: djBackends
--

CREATE INDEX cita_key_mascota_id_b08a436e ON public.cita USING btree (key_mascota_id);


--
-- TOC entry 3440 (class 1259 OID 16777)
-- Name: cita_key_servicio_id_022fd7cc; Type: INDEX; Schema: public; Owner: djBackends
--

CREATE INDEX cita_key_servicio_id_022fd7cc ON public.cita USING btree (key_servicio_id);


--
-- TOC entry 3441 (class 1259 OID 16763)
-- Name: cita_key_tipo_cita_id_d430404d; Type: INDEX; Schema: public; Owner: djBackends
--

CREATE INDEX cita_key_tipo_cita_id_d430404d ON public.cita USING btree (key_tipo_cita_id);


--
-- TOC entry 3442 (class 1259 OID 16616)
-- Name: cita_key_veterinario_id_d6091844; Type: INDEX; Schema: public; Owner: djBackends
--

CREATE INDEX cita_key_veterinario_id_d6091844 ON public.cita USING btree (key_veterinario_id);


--
-- TOC entry 3405 (class 1259 OID 16592)
-- Name: cliente_key_estado_id_f417a742; Type: INDEX; Schema: public; Owner: djBackends
--

CREATE INDEX cliente_key_estado_id_f417a742 ON public.cliente USING btree (key_estado_id);


--
-- TOC entry 3445 (class 1259 OID 16637)
-- Name: django_admin_log_content_type_id_c4bce8eb; Type: INDEX; Schema: public; Owner: djBackends
--

CREATE INDEX django_admin_log_content_type_id_c4bce8eb ON public.django_admin_log USING btree (content_type_id);


--
-- TOC entry 3448 (class 1259 OID 16638)
-- Name: django_admin_log_user_id_c564eba6; Type: INDEX; Schema: public; Owner: djBackends
--

CREATE INDEX django_admin_log_user_id_c564eba6 ON public.django_admin_log USING btree (user_id);


--
-- TOC entry 3522 (class 1259 OID 17042)
-- Name: django_session_expire_date_a5c62663; Type: INDEX; Schema: public; Owner: djBackends
--

CREATE INDEX django_session_expire_date_a5c62663 ON public.django_session USING btree (expire_date);


--
-- TOC entry 3525 (class 1259 OID 17041)
-- Name: django_session_session_key_c0390e0f_like; Type: INDEX; Schema: public; Owner: djBackends
--

CREATE INDEX django_session_session_key_c0390e0f_like ON public.django_session USING btree (session_key varchar_pattern_ops);


--
-- TOC entry 3408 (class 1259 OID 16591)
-- Name: estado_key_tipo_estado_id_70d57447; Type: INDEX; Schema: public; Owner: djBackends
--

CREATE INDEX estado_key_tipo_estado_id_70d57447 ON public.estado USING btree (key_tipo_estado_id);


--
-- TOC entry 3433 (class 1259 OID 16589)
-- Name: log_key_evento_id_7ea260e9; Type: INDEX; Schema: public; Owner: djBackends
--

CREATE INDEX log_key_evento_id_7ea260e9 ON public.log USING btree (key_evento_id);


--
-- TOC entry 3434 (class 1259 OID 16922)
-- Name: log_key_usuario_id_89163f95; Type: INDEX; Schema: public; Owner: djBackends
--

CREATE INDEX log_key_usuario_id_89163f95 ON public.log USING btree (key_usuario_id);


--
-- TOC entry 3427 (class 1259 OID 16576)
-- Name: mascota_key_cliente_id_49312869; Type: INDEX; Schema: public; Owner: djBackends
--

CREATE INDEX mascota_key_cliente_id_49312869 ON public.mascota USING btree (key_cliente_id);


--
-- TOC entry 3428 (class 1259 OID 16577)
-- Name: mascota_key_estado_id_2806b5db; Type: INDEX; Schema: public; Owner: djBackends
--

CREATE INDEX mascota_key_estado_id_2806b5db ON public.mascota USING btree (key_estado_id);


--
-- TOC entry 3429 (class 1259 OID 16578)
-- Name: mascota_key_raza_id_fd1ba9d3; Type: INDEX; Schema: public; Owner: djBackends
--

CREATE INDEX mascota_key_raza_id_fd1ba9d3 ON public.mascota USING btree (key_raza_id);


--
-- TOC entry 3430 (class 1259 OID 16742)
-- Name: mascota_key_tipo_mascota_id_ab7fe731; Type: INDEX; Schema: public; Owner: djBackends
--

CREATE INDEX mascota_key_tipo_mascota_id_ab7fe731 ON public.mascota USING btree (key_tipo_mascota_id);


--
-- TOC entry 3509 (class 1259 OID 16994)
-- Name: medicina_key_estado_id_1c00e357; Type: INDEX; Schema: public; Owner: djBackends
--

CREATE INDEX medicina_key_estado_id_1c00e357 ON public.medicina USING btree (key_estado_id);


--
-- TOC entry 3474 (class 1259 OID 16792)
-- Name: pregunta_frecuente_key_estado_id_8de641c0; Type: INDEX; Schema: public; Owner: djBackends
--

CREATE INDEX pregunta_frecuente_key_estado_id_8de641c0 ON public.pregunta_frecuente USING btree (key_estado_id);


--
-- TOC entry 3413 (class 1259 OID 16727)
-- Name: raza_key_estado_id_58c3f211; Type: INDEX; Schema: public; Owner: djBackends
--

CREATE INDEX raza_key_estado_id_58c3f211 ON public.raza USING btree (key_estado_id);


--
-- TOC entry 3515 (class 1259 OID 17011)
-- Name: receta_key_cita_id_232be499; Type: INDEX; Schema: public; Owner: djBackends
--

CREATE INDEX receta_key_cita_id_232be499 ON public.receta USING btree (key_cita_id);


--
-- TOC entry 3526 (class 1259 OID 49167)
-- Name: restablecer_usuario_key_usuario_id_3fbcd0d7; Type: INDEX; Schema: public; Owner: djBackends
--

CREATE INDEX restablecer_usuario_key_usuario_id_3fbcd0d7 ON public.restablecer_usuario USING btree (key_usuario_id);


--
-- TOC entry 3416 (class 1259 OID 16693)
-- Name: servicio_key_estado_id_0aced3e9; Type: INDEX; Schema: public; Owner: djBackends
--

CREATE INDEX servicio_key_estado_id_0aced3e9 ON public.servicio USING btree (key_estado_id);


--
-- TOC entry 3417 (class 1259 OID 16708)
-- Name: servicio_key_tipo_servicio_id_660b1023; Type: INDEX; Schema: public; Owner: djBackends
--

CREATE INDEX servicio_key_tipo_servicio_id_660b1023 ON public.servicio USING btree (key_tipo_servicio_id);


--
-- TOC entry 3471 (class 1259 OID 16769)
-- Name: tipo_cita_key_estado_id_c3404ea8; Type: INDEX; Schema: public; Owner: djBackends
--

CREATE INDEX tipo_cita_key_estado_id_c3404ea8 ON public.tipo_cita USING btree (key_estado_id);


--
-- TOC entry 3468 (class 1259 OID 16748)
-- Name: tipo_mascota_key_estado_id_75e92dc2; Type: INDEX; Schema: public; Owner: djBackends
--

CREATE INDEX tipo_mascota_key_estado_id_75e92dc2 ON public.tipo_mascota USING btree (key_estado_id);


--
-- TOC entry 3465 (class 1259 OID 16714)
-- Name: tipo_servicio_key_estado_id_731282ba; Type: INDEX; Schema: public; Owner: djBackends
--

CREATE INDEX tipo_servicio_key_estado_id_731282ba ON public.tipo_servicio USING btree (key_estado_id);


--
-- TOC entry 3512 (class 1259 OID 17000)
-- Name: triaje_key_cita_id_3311524e; Type: INDEX; Schema: public; Owner: djBackends
--

CREATE INDEX triaje_key_cita_id_3311524e ON public.triaje USING btree (key_cita_id);


--
-- TOC entry 3494 (class 1259 OID 16893)
-- Name: usuario_groups_group_id_c67c8651; Type: INDEX; Schema: public; Owner: djBackends
--

CREATE INDEX usuario_groups_group_id_c67c8651 ON public.usuario_groups USING btree (group_id);


--
-- TOC entry 3497 (class 1259 OID 16892)
-- Name: usuario_groups_usuario_id_161fc80c; Type: INDEX; Schema: public; Owner: djBackends
--

CREATE INDEX usuario_groups_usuario_id_161fc80c ON public.usuario_groups USING btree (usuario_id);


--
-- TOC entry 3484 (class 1259 OID 16879)
-- Name: usuario_num_documento_b166d578_like; Type: INDEX; Schema: public; Owner: djBackends
--

CREATE INDEX usuario_num_documento_b166d578_like ON public.usuario USING btree (document_number text_pattern_ops);


--
-- TOC entry 3489 (class 1259 OID 16934)
-- Name: usuario_status_id_bd80a2a8; Type: INDEX; Schema: public; Owner: djBackends
--

CREATE INDEX usuario_status_id_bd80a2a8 ON public.usuario USING btree (status_id);


--
-- TOC entry 3490 (class 1259 OID 16928)
-- Name: usuario_userType_id_23e937e2; Type: INDEX; Schema: public; Owner: djBackends
--

CREATE INDEX "usuario_userType_id_23e937e2" ON public.usuario USING btree (user_type_id);


--
-- TOC entry 3500 (class 1259 OID 16921)
-- Name: usuario_user_permissions_permission_id_a8893ce7; Type: INDEX; Schema: public; Owner: djBackends
--

CREATE INDEX usuario_user_permissions_permission_id_a8893ce7 ON public.usuario_user_permissions USING btree (permission_id);


--
-- TOC entry 3503 (class 1259 OID 16920)
-- Name: usuario_user_permissions_usuario_id_693d9c50; Type: INDEX; Schema: public; Owner: djBackends
--

CREATE INDEX usuario_user_permissions_usuario_id_693d9c50 ON public.usuario_user_permissions USING btree (usuario_id);


--
-- TOC entry 3491 (class 1259 OID 16878)
-- Name: usuario_username_7e1fc9dc_like; Type: INDEX; Schema: public; Owner: djBackends
--

CREATE INDEX usuario_username_7e1fc9dc_like ON public.usuario USING btree (username varchar_pattern_ops);


--
-- TOC entry 3424 (class 1259 OID 16536)
-- Name: veterinario_key_estado_id_6551fdbc; Type: INDEX; Schema: public; Owner: djBackends
--

CREATE INDEX veterinario_key_estado_id_6551fdbc ON public.veterinario USING btree (key_estado_id);


--
-- TOC entry 3568 (class 2606 OID 17022)
-- Name: detalle_receta app_veterinaria_deta_key_medicamento_id_30cc9e92_fk_medicina_; Type: FK CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.detalle_receta
    ADD CONSTRAINT app_veterinaria_deta_key_medicamento_id_30cc9e92_fk_medicina_ FOREIGN KEY (key_medicamento_id) REFERENCES public.medicina(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 3569 (class 2606 OID 17027)
-- Name: detalle_receta app_veterinaria_deta_key_receta_id_a1069b76_fk_receta_id; Type: FK CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.detalle_receta
    ADD CONSTRAINT app_veterinaria_deta_key_receta_id_a1069b76_fk_receta_id FOREIGN KEY (key_receta_id) REFERENCES public.receta(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 3564 (class 2606 OID 16955)
-- Name: permiso app_veterinaria_permiso_key_estado_id_6f1d860a_fk_estado_id; Type: FK CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.permiso
    ADD CONSTRAINT app_veterinaria_permiso_key_estado_id_6f1d860a_fk_estado_id FOREIGN KEY (key_estado_id) REFERENCES public.estado(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 3555 (class 2606 OID 16809)
-- Name: asignacion_permiso asignacion_permiso_key_menu_id_96681a91_fk_menu_id; Type: FK CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.asignacion_permiso
    ADD CONSTRAINT asignacion_permiso_key_menu_id_96681a91_fk_menu_id FOREIGN KEY (key_menu_id) REFERENCES public.menu(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 3556 (class 2606 OID 16950)
-- Name: asignacion_permiso asignacion_permiso_key_permiso_id_e599b6ac_fk_app_veter; Type: FK CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.asignacion_permiso
    ADD CONSTRAINT asignacion_permiso_key_permiso_id_e599b6ac_fk_app_veter FOREIGN KEY (key_permiso_id) REFERENCES public.permiso(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 3557 (class 2606 OID 16830)
-- Name: asignacion_permiso asignacion_permiso_key_tipo_usuario_id_8f4c6a7b_fk_tipo_usua; Type: FK CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.asignacion_permiso
    ADD CONSTRAINT asignacion_permiso_key_tipo_usuario_id_8f4c6a7b_fk_tipo_usua FOREIGN KEY (key_tipo_usuario_id) REFERENCES public.tipo_usuario(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 3549 (class 2606 OID 16678)
-- Name: auth_group_permissions auth_group_permissio_permission_id_84c5c92e_fk_auth_perm; Type: FK CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.auth_group_permissions
    ADD CONSTRAINT auth_group_permissio_permission_id_84c5c92e_fk_auth_perm FOREIGN KEY (permission_id) REFERENCES public.auth_permission(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 3550 (class 2606 OID 16673)
-- Name: auth_group_permissions auth_group_permissions_group_id_b120cbf9_fk_auth_group_id; Type: FK CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.auth_group_permissions
    ADD CONSTRAINT auth_group_permissions_group_id_b120cbf9_fk_auth_group_id FOREIGN KEY (group_id) REFERENCES public.auth_group(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 3548 (class 2606 OID 16664)
-- Name: auth_permission auth_permission_content_type_id_2f476e4b_fk_django_co; Type: FK CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.auth_permission
    ADD CONSTRAINT auth_permission_content_type_id_2f476e4b_fk_django_co FOREIGN KEY (content_type_id) REFERENCES public.django_content_type(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 3541 (class 2606 OID 16593)
-- Name: cita cita_key_cliente_id_e7c6d0d6_fk_cliente_id; Type: FK CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.cita
    ADD CONSTRAINT cita_key_cliente_id_e7c6d0d6_fk_cliente_id FOREIGN KEY (key_cliente_id) REFERENCES public.cliente(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 3542 (class 2606 OID 16598)
-- Name: cita cita_key_estado_id_3d3aea8a_fk_estado_id; Type: FK CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.cita
    ADD CONSTRAINT cita_key_estado_id_3d3aea8a_fk_estado_id FOREIGN KEY (key_estado_id) REFERENCES public.estado(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 3543 (class 2606 OID 16603)
-- Name: cita cita_key_mascota_id_b08a436e_fk_mascota_id; Type: FK CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.cita
    ADD CONSTRAINT cita_key_mascota_id_b08a436e_fk_mascota_id FOREIGN KEY (key_mascota_id) REFERENCES public.mascota(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 3544 (class 2606 OID 16772)
-- Name: cita cita_key_servicio_id_022fd7cc_fk_servicio_id; Type: FK CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.cita
    ADD CONSTRAINT cita_key_servicio_id_022fd7cc_fk_servicio_id FOREIGN KEY (key_servicio_id) REFERENCES public.servicio(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 3545 (class 2606 OID 16758)
-- Name: cita cita_key_tipo_cita_id_d430404d_fk_tipo_cita_id; Type: FK CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.cita
    ADD CONSTRAINT cita_key_tipo_cita_id_d430404d_fk_tipo_cita_id FOREIGN KEY (key_tipo_cita_id) REFERENCES public.tipo_cita(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 3546 (class 2606 OID 16608)
-- Name: cita cita_key_veterinario_id_d6091844_fk_veterinario_id; Type: FK CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.cita
    ADD CONSTRAINT cita_key_veterinario_id_d6091844_fk_veterinario_id FOREIGN KEY (key_veterinario_id) REFERENCES public.veterinario(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 3529 (class 2606 OID 16519)
-- Name: cliente cliente_key_estado_id_f417a742_fk_estado_id; Type: FK CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.cliente
    ADD CONSTRAINT cliente_key_estado_id_f417a742_fk_estado_id FOREIGN KEY (key_estado_id) REFERENCES public.estado(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 3547 (class 2606 OID 16627)
-- Name: django_admin_log django_admin_log_content_type_id_c4bce8eb_fk_django_co; Type: FK CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.django_admin_log
    ADD CONSTRAINT django_admin_log_content_type_id_c4bce8eb_fk_django_co FOREIGN KEY (content_type_id) REFERENCES public.django_content_type(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 3530 (class 2606 OID 16514)
-- Name: estado estado_key_tipo_estado_id_70d57447_fk_tipo_estado_id; Type: FK CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.estado
    ADD CONSTRAINT estado_key_tipo_estado_id_70d57447_fk_tipo_estado_id FOREIGN KEY (key_tipo_estado_id) REFERENCES public.tipo_estado(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 3539 (class 2606 OID 16579)
-- Name: log log_key_evento_id_7ea260e9_fk_evento_id; Type: FK CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.log
    ADD CONSTRAINT log_key_evento_id_7ea260e9_fk_evento_id FOREIGN KEY (key_evento_id) REFERENCES public.evento(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 3540 (class 2606 OID 16873)
-- Name: log log_key_usuario_id_89163f95_fk_usuario_id; Type: FK CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.log
    ADD CONSTRAINT log_key_usuario_id_89163f95_fk_usuario_id FOREIGN KEY (key_usuario_id) REFERENCES public.usuario(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 3535 (class 2606 OID 16561)
-- Name: mascota mascota_key_cliente_id_49312869_fk_cliente_id; Type: FK CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.mascota
    ADD CONSTRAINT mascota_key_cliente_id_49312869_fk_cliente_id FOREIGN KEY (key_cliente_id) REFERENCES public.cliente(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 3536 (class 2606 OID 16566)
-- Name: mascota mascota_key_estado_id_2806b5db_fk_estado_id; Type: FK CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.mascota
    ADD CONSTRAINT mascota_key_estado_id_2806b5db_fk_estado_id FOREIGN KEY (key_estado_id) REFERENCES public.estado(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 3537 (class 2606 OID 16571)
-- Name: mascota mascota_key_raza_id_fd1ba9d3_fk_raza_id; Type: FK CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.mascota
    ADD CONSTRAINT mascota_key_raza_id_fd1ba9d3_fk_raza_id FOREIGN KEY (key_raza_id) REFERENCES public.raza(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 3538 (class 2606 OID 16737)
-- Name: mascota mascota_key_tipo_mascota_id_ab7fe731_fk_tipo_mascota_id; Type: FK CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.mascota
    ADD CONSTRAINT mascota_key_tipo_mascota_id_ab7fe731_fk_tipo_mascota_id FOREIGN KEY (key_tipo_mascota_id) REFERENCES public.tipo_mascota(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 3565 (class 2606 OID 16989)
-- Name: medicina medicina_key_estado_id_1c00e357_fk_estado_id; Type: FK CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.medicina
    ADD CONSTRAINT medicina_key_estado_id_1c00e357_fk_estado_id FOREIGN KEY (key_estado_id) REFERENCES public.estado(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 3554 (class 2606 OID 16787)
-- Name: pregunta_frecuente pregunta_frecuente_key_estado_id_8de641c0_fk_estado_id; Type: FK CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.pregunta_frecuente
    ADD CONSTRAINT pregunta_frecuente_key_estado_id_8de641c0_fk_estado_id FOREIGN KEY (key_estado_id) REFERENCES public.estado(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 3531 (class 2606 OID 16722)
-- Name: raza raza_key_estado_id_58c3f211_fk_estado_id; Type: FK CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.raza
    ADD CONSTRAINT raza_key_estado_id_58c3f211_fk_estado_id FOREIGN KEY (key_estado_id) REFERENCES public.estado(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 3567 (class 2606 OID 17001)
-- Name: receta receta_key_cita_id_232be499_fk_cita_id; Type: FK CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.receta
    ADD CONSTRAINT receta_key_cita_id_232be499_fk_cita_id FOREIGN KEY (key_cita_id) REFERENCES public.cita(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 3570 (class 2606 OID 49162)
-- Name: restablecer_usuario restablecer_usuario_key_usuario_id_3fbcd0d7_fk_usuario_id; Type: FK CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.restablecer_usuario
    ADD CONSTRAINT restablecer_usuario_key_usuario_id_3fbcd0d7_fk_usuario_id FOREIGN KEY (key_usuario_id) REFERENCES public.usuario(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 3532 (class 2606 OID 16688)
-- Name: servicio servicio_key_estado_id_0aced3e9_fk_estado_id; Type: FK CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.servicio
    ADD CONSTRAINT servicio_key_estado_id_0aced3e9_fk_estado_id FOREIGN KEY (key_estado_id) REFERENCES public.estado(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 3533 (class 2606 OID 16703)
-- Name: servicio servicio_key_tipo_servicio_id_660b1023_fk_tipo_servicio_id; Type: FK CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.servicio
    ADD CONSTRAINT servicio_key_tipo_servicio_id_660b1023_fk_tipo_servicio_id FOREIGN KEY (key_tipo_servicio_id) REFERENCES public.tipo_servicio(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 3553 (class 2606 OID 16764)
-- Name: tipo_cita tipo_cita_key_estado_id_c3404ea8_fk_estado_id; Type: FK CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.tipo_cita
    ADD CONSTRAINT tipo_cita_key_estado_id_c3404ea8_fk_estado_id FOREIGN KEY (key_estado_id) REFERENCES public.estado(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 3552 (class 2606 OID 16743)
-- Name: tipo_mascota tipo_mascota_key_estado_id_75e92dc2_fk_estado_id; Type: FK CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.tipo_mascota
    ADD CONSTRAINT tipo_mascota_key_estado_id_75e92dc2_fk_estado_id FOREIGN KEY (key_estado_id) REFERENCES public.estado(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 3551 (class 2606 OID 16709)
-- Name: tipo_servicio tipo_servicio_key_estado_id_731282ba_fk_estado_id; Type: FK CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.tipo_servicio
    ADD CONSTRAINT tipo_servicio_key_estado_id_731282ba_fk_estado_id FOREIGN KEY (key_estado_id) REFERENCES public.estado(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 3566 (class 2606 OID 16995)
-- Name: triaje triaje_key_cita_id_3311524e_fk_cita_id; Type: FK CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.triaje
    ADD CONSTRAINT triaje_key_cita_id_3311524e_fk_cita_id FOREIGN KEY (key_cita_id) REFERENCES public.cita(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 3560 (class 2606 OID 16887)
-- Name: usuario_groups usuario_groups_group_id_c67c8651_fk_auth_group_id; Type: FK CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.usuario_groups
    ADD CONSTRAINT usuario_groups_group_id_c67c8651_fk_auth_group_id FOREIGN KEY (group_id) REFERENCES public.auth_group(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 3561 (class 2606 OID 16882)
-- Name: usuario_groups usuario_groups_usuario_id_161fc80c_fk_usuario_id; Type: FK CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.usuario_groups
    ADD CONSTRAINT usuario_groups_usuario_id_161fc80c_fk_usuario_id FOREIGN KEY (usuario_id) REFERENCES public.usuario(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 3558 (class 2606 OID 16929)
-- Name: usuario usuario_status_id_bd80a2a8_fk_estado_id; Type: FK CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_status_id_bd80a2a8_fk_estado_id FOREIGN KEY (status_id) REFERENCES public.estado(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 3562 (class 2606 OID 16915)
-- Name: usuario_user_permissions usuario_user_permiss_permission_id_a8893ce7_fk_auth_perm; Type: FK CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.usuario_user_permissions
    ADD CONSTRAINT usuario_user_permiss_permission_id_a8893ce7_fk_auth_perm FOREIGN KEY (permission_id) REFERENCES public.auth_permission(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 3563 (class 2606 OID 16910)
-- Name: usuario_user_permissions usuario_user_permissions_usuario_id_693d9c50_fk_usuario_id; Type: FK CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.usuario_user_permissions
    ADD CONSTRAINT usuario_user_permissions_usuario_id_693d9c50_fk_usuario_id FOREIGN KEY (usuario_id) REFERENCES public.usuario(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 3559 (class 2606 OID 16935)
-- Name: usuario usuario_user_type_id_e0045640_fk_tipo_usuario_id; Type: FK CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_user_type_id_e0045640_fk_tipo_usuario_id FOREIGN KEY (user_type_id) REFERENCES public.tipo_usuario(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 3534 (class 2606 OID 16531)
-- Name: veterinario veterinario_key_estado_id_6551fdbc_fk_estado_id; Type: FK CONSTRAINT; Schema: public; Owner: djBackends
--

ALTER TABLE ONLY public.veterinario
    ADD CONSTRAINT veterinario_key_estado_id_6551fdbc_fk_estado_id FOREIGN KEY (key_estado_id) REFERENCES public.estado(id) DEFERRABLE INITIALLY DEFERRED;


-- Completed on 2024-06-15 22:03:34 UTC

--
-- PostgreSQL database dump complete
--

