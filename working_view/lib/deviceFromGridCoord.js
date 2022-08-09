import DEVICE_DIM_MAP from '../components/ConstantDeviceDimMap'

/**
 * Gets device information from grid coordinates and list of deployed devices
 * @param {number} gridX
 * @param {number} gridY
 * @param {Array} devices - from db deployed devices
 * @returns {object}
 */
function deviceFromGridCoord(gridX, gridY, devices) {
  let dimension
  const device = devices.find((d) => {
    const type = parseInt(d.type)
    dimension = DEVICE_DIM_MAP.get(type)

    if (!d.base_grid) return

    return (
      gridX >= d.base_grid.x &&
      gridX < d.base_grid.x + dimension &&
      gridY >= d.base_grid.y &&
      gridY < d.base_grid.y + dimension
    )
  })

  if (!device) return

  return {
    device,
    dimension
  }
}

export default deviceFromGridCoord
