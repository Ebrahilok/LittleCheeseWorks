import { useState } from 'react';
import { Pressable, View } from 'react-native';
import type { GestureResponderEvent, LayoutChangeEvent } from 'react-native';
import Svg, { Circle, G, Line, Polyline, Rect, Text as SvgText } from 'react-native-svg';
import { ajustarAlCuarto, distancia, limites } from '@/features/robot/modelo';
import type { Cuarto, ObjetoDetectado, Punto, StatusRobot } from '@/features/robot/modelo';
import { Colores } from '@/constants/Theme';

interface Props {
  cuarto: Cuarto;
  status?: StatusRobot | null;
  objetos?: ObjetoDetectado[];
  puntos?: { nombre: string; x: number; y: number }[];
  recorrido?: Punto[];
  seleccionado?: Punto | null;
  onTocar?: (p: Punto) => void;
  onMantener?: (p: Punto) => void;
  /** Alto máximo en píxeles (el ancho se ajusta al espacio disponible). */
  altoMax?: number;
}

/** Vista superior del cuarto: base, puntos guardados, objetos, recorrido y robot. */
export function MapaCuarto({ cuarto, status, objetos = [], puntos = [], recorrido = [], seleccionado, onTocar, onMantener, altoMax = 520 }: Props) {
  const [anchoDisp, setAnchoDisp] = useState(0);
  const l = limites(cuarto);
  const proporcion = cuarto.largo / cuarto.ancho;
  let ancho = anchoDisp;
  let alto = ancho * proporcion;
  if (alto > altoMax) {
    alto = altoMax;
    ancho = alto / proporcion;
  }
  const escala = ancho / cuarto.ancho;
  const px = (x: number) => (x - l.minX) * escala;
  const py = (y: number) => (y - l.minY) * escala;

  const aMetros = (e: GestureResponderEvent): Punto =>
    ajustarAlCuarto(cuarto, { x: l.minX + e.nativeEvent.locationX / escala, y: l.minY + e.nativeEvent.locationY / escala });

  const lineas: number[] = [];
  for (let x = Math.ceil(l.minX); x <= l.maxX; x++) lineas.push(x);
  const lineasY: number[] = [];
  for (let y = Math.ceil(l.minY); y <= l.maxY; y++) lineasY.push(y);

  const destino = status?.destino ?? null;
  const mostrarSeleccion = seleccionado && (!destino || distancia(seleccionado, destino) > 0.01);

  return (
    <View onLayout={(e: LayoutChangeEvent) => setAnchoDisp(e.nativeEvent.layout.width)} style={{ width: '100%', alignItems: 'center' }}>
      {ancho > 0 && (
        <Pressable
          onPress={onTocar ? (e) => onTocar(aMetros(e)) : undefined}
          onLongPress={onMantener ? (e) => onMantener(aMetros(e)) : undefined}
          accessibilityLabel="Mapa del cuarto"
          style={{ width: ancho, height: alto }}
        >
          <Svg width={ancho} height={alto} pointerEvents="none">
            <Rect x={0} y={0} width={ancho} height={alto} fill={Colores.piso} />
            {lineas.map((x) => <Line key={`x${x}`} x1={px(x)} y1={0} x2={px(x)} y2={alto} stroke="rgba(0,0,0,0.12)" strokeWidth={1} />)}
            {lineasY.map((y) => <Line key={`y${y}`} x1={0} y1={py(y)} x2={ancho} y2={py(y)} stroke="rgba(0,0,0,0.12)" strokeWidth={1} />)}
            <Rect x={1.5} y={1.5} width={ancho - 3} height={alto - 3} fill="none" stroke="#8A8F98" strokeWidth={3} />

            {/* Base */}
            <Rect x={px(-0.25)} y={py(-0.25)} width={0.5 * escala} height={0.5 * escala} fill={Colores.base} />
            <SvgText x={px(0)} y={py(0.25) + 13} fontSize={11} fill="#2E7D32" textAnchor="middle">Base</SvgText>

            {puntos.map((p, i) => (
              <G key={`p${i}`}>
                <Circle cx={px(p.x)} cy={py(p.y)} r={5} fill={Colores.punto} />
                <SvgText x={px(p.x)} y={py(p.y) + 17} fontSize={11} fill="#333" textAnchor="middle">{p.nombre}</SvgText>
              </G>
            ))}

            {objetos.map((o) => (
              <Rect key={`o${o.id}`} x={px(o.x - o.w / 2)} y={py(o.y - o.h / 2)} width={o.w * escala} height={o.h * escala} fill={Colores.objeto} />
            ))}

            {recorrido.length > 1 && (
              <Polyline points={recorrido.map((p) => `${px(p.x)},${py(p.y)}`).join(' ')} fill="none"
                stroke={Colores.recorrido} strokeWidth={3} strokeLinejoin="round" />
            )}

            {status && destino && (
              <>
                <Line x1={px(status.x)} y1={py(status.y)} x2={px(destino.x)} y2={py(destino.y)} stroke="#1E88E5" strokeWidth={2} />
                <Marcador x={px(destino.x)} y={py(destino.y)} color={Colores.destino} />
              </>
            )}
            {mostrarSeleccion && <Marcador x={px(seleccionado!.x)} y={py(seleccionado!.y)} color={Colores.seleccion} r={11} />}

            {status && (
              <G>
                <Circle cx={px(status.x)} cy={py(status.y)} r={10} fill={Colores.robot} />
                <Line x1={px(status.x)} y1={py(status.y)}
                  x2={px(status.x) + Math.cos(status.rumbo) * 18} y2={py(status.y) + Math.sin(status.rumbo) * 18}
                  stroke={Colores.rumbo} strokeWidth={4} strokeLinecap="round" />
                {status.conCarga && <Circle cx={px(status.x)} cy={py(status.y)} r={4} fill={Colores.carga} />}
              </G>
            )}
          </Svg>
        </Pressable>
      )}
    </View>
  );
}

function Marcador({ x, y, color, r = 9 }: { x: number; y: number; color: string; r?: number }) {
  return (
    <G>
      <Circle cx={x} cy={y} r={r} fill="none" stroke={color} strokeWidth={3} />
      <Line x1={x - r - 4} y1={y} x2={x + r + 4} y2={y} stroke={color} strokeWidth={3} />
      <Line x1={x} y1={y - r - 4} x2={x} y2={y + r + 4} stroke={color} strokeWidth={3} />
    </G>
  );
}
