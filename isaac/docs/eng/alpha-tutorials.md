# Open Alpha: Tutorials

### StarDisc

**Register your Discord handle**: Register your Discord handle at [StarDisc](https://stardisc.netlify.app).

<img src="/assets/images/stardisc-screenshot.png"/>

### Station
1. **Join the queue**: Visit [Isaac Station](https://isaac-station.netlify.app), connect wallet, and join the queue.

2. **Dispatch to universe**: Once the queue is full, dispatch all queued players to Universe#0.
(anyone can submit this transaction once queue is full)

3. **Examine past civilization**: Select open history, and click on civilization's fate to open civilization replay window. Use slide bar to navigate block numbers relative to civilization birth.

### Space View

**Check the whereabouts of Böyük, Orta, Balaca, and Ev**: Visit [Isaac Space View](https://isaac-space-view.netlify.app/).

<img src="/assets/images/space-view-screenshot.png"/>

### Working View

**Inspect and participate in strategic manufacturing activites**: Visit [Isaac Working View](https://isaac-working-view.netlify.app/).

##### **Connect wallet**
Connect wallet, and find your registered Discord handle shown under *Player accounts in this universe*. Also examine the civilization stats as well as your starting loadout - the balance of each device type at the birth of civilization.

<video controls="controls" width="800" height="400" name="tutorial-connect-wallet">
  <source src="/assets/videos/tutorial-connect-wallet.mov">
</video>


##### **Panning & zoom in/out**
Right mouse button down to pan; mouse wheel down/up to zoom in/out. For Mac touchpad users, right mouse button is equivalent to two finger tap; mouse wheel down/up is equivalent to two finger swipe down/up. Notice HUD (heads up display) showing the grid coordinate and the planet face of where your mouse cursor is.

<video controls="controls" width="800" height="400" name="tutorial-pan-zoom">
  <source src="/assets/videos/tutorial-pan-zoom.mov">
</video>


3. **Reset zoom and position**: Press 'c'.

<video controls="controls" width="800" height="400" name="tutorial-reset-zoom">
  <source src="/assets/videos/tutorial-reset-zoom.mov">
</video>


4. **Switch display mode to viewing resource distributions**: Press '1' to '6' to view the distribution of raw Fe, raw Al to raw Pu. Notice HUD showing the current display mode.

<video controls="controls" width="800" height="400" name="tutorial-display-mode">
  <source src="/assets/videos/tutorial-display-mode.mov">
</video>


5. **Peer to peer device transfer**: press '7'. Specify the player index of receiver. Press esc to close the popup window.

<video controls="controls" width="800" height="400" name="tutorial-transfer">
  <source src="/assets/videos/tutorial-transfer.mov">
</video>


6. **Deploy a device**: click on a grid, and click "Deploy ...". Approve the transaction. Watch out for device's footprint - overlapping is illegal. Unavailable options - devices which you have 0 balance of - are greyed out. Press esc to close the popup window. Pending deploy is indicated by a *glowing animation*. (Future UX improvement: mouse cursor dragging a semi-transparent device on the map to help with positioning)

<video controls="controls" width="800" height="400" name="tutorial-deploy">
  <source src="/assets/videos/tutorial-deploy.mov">
</video>


7. **Pick up a device**: click on a deployed device, make sure you are its owner, and click "Pick up ...". Approve the transaction. Pending pickup is indicated by a *glowing & pulsating animation*. You can not pick up a device that you do not own. (Future UX improvement: highlight devices owned by the signed-in player.)

<video controls="controls" width="800" height="400" name="tutorial-pickup">
  <source src="/assets/videos/tutorial-pickup.mov">
</video>


8. **Connect a resource source device to a resource destination device via UTB**: UTB can transport resource from a suitable source device to a suitable destination device. In the following example, 3 contiguous UTBs are deployed to connect an Cu Harvester to UPSF. First, left mouse button down on the source device grid, drag along the desirable contiguous path to the destination device grid, then release left mouse button. Double check grid coordinates along the path in popup window. Choose "Deploy UTB".

<video controls="controls" width="800" height="400" name="tutorial-utb">
  <source src="/assets/videos/tutorial-utb.mov">
</video>


9. **Connect an energy source device to an energy receiver device**: Repeat the above steps, starting from a power generator and ending at any energy-receiving device. Choose "Deploy UTL".

<video controls="controls" width="800" height="400" name="tutorial-utl">
  <source src="/assets/videos/tutorial-utl.mov">
</video>


10. **Manufacture device at UPSF**: Click on UPSF. Hover over different build options and see their manufacture requirements on the left. Unmet requirements are in red. You can specify amount to manufacture multiple devices of the same type in one transaction. Approve transaction.
<video controls="controls" width="800" height="400" name="tutorial-manufacture">
  <source src="/assets/videos/tutorial-manufacture.mov">
</video>

