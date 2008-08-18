import org.openscience.cdk.Atom;
import org.openscience.cdk.AtomContainer;
import org.openscience.cdk.CDKConstants;
import org.openscience.cdk.DefaultChemObjectBuilder;
import org.openscience.cdk.config.Elements;
import org.openscience.cdk.geometry.GeometryTools;
import org.openscience.cdk.interfaces.IAtomContainer;
import org.openscience.cdk.interfaces.IMolecule;
import org.openscience.cdk.interfaces.IMoleculeSet;
import org.openscience.cdk.interfaces.IAtom;
import org.openscience.cdk.interfaces.IBond;
import org.openscience.cdk.isomorphism.UniversalIsomorphismTester;
import org.openscience.cdk.isomorphism.mcss.RMap;
import org.openscience.cdk.layout.StructureDiagramGenerator;
import org.openscience.cdk.renderer.Renderer2D;
import org.openscience.cdk.renderer.Renderer2DModel;
import org.openscience.cdk.smiles.SmilesParser;
import org.openscience.cdk.smiles.smarts.SMARTSQueryTool;
import org.openscience.cdk.smiles.smarts.SMARTSParser;
import org.openscience.cdk.graph.ConnectivityChecker;

import javax.swing.*;
import java.awt.*;
import java.util.Map;
import java.util.HashSet;
import java.util.HashMap;
import java.util.Hashtable;
import java.util.List;
import java.util.ArrayList;
import java.util.Vector;
import java.util.Iterator;
import java.awt.image.BufferedImage;
import java.awt.Dimension;
import java.lang.Math;

public class DisplayStructure {

  Renderer2DModel r2dm;
  Renderer2D renderer;
	SmilesParser sp; 
	StructureDiagramGenerator sdg;
	IAtomContainer molecule;
	IMoleculeSet moleculeSet; 
	SMARTSQueryTool querytool;
	List mappings ;
	IAtomContainer matches;
	Vector<Integer> idlist;
	int size;
	BufferedImage image;

  public BufferedImage displaySmiles(String smiles) {

		coordinateSmiles(smiles);
		setDisplayOptions();
		arrangeAndPaintImage();

		return image;

  }

  public BufferedImage displaySubstructureP(String smiles, String[] active_smarts, String[] inactive_smarts, String[] unknown_smarts, String[] active_p, String[] inactive_p) {


		// get p values
		Float[] fap = new Float[active_p.length];
		for (int i=0; i<active_p.length; i++) { fap[i] = Float.valueOf(active_p[i].trim()); }
		Float[] fiap = new Float[inactive_p.length];
		for (int i=0; i<inactive_p.length; i++) { fiap[i] = Float.valueOf(inactive_p[i].trim()); }

		/*
		System.out.print("Active Smarts: ");
		System.out.println(active_smarts.length);
		System.out.print("Inactive Smarts: ");
		System.out.println(inactive_smarts.length);
		*/

		coordinateSmiles(smiles);
		setDisplayOptions();

		
		Map<IBond,Float> all_bonds = new HashMap<IBond,Float>();

		int i = 0;
		for (String ias : inactive_smarts) { 
			List iab = getBondsFromSmarts(ias); 
			//System.out.println(ias + " " + i + "(" + fiap[i] + ")");
			for (Object b_new : iab) {
				Float old_p = all_bonds.get((IBond) b_new);
				if (old_p == null) { 
					//System.out.println("null"); 
					all_bonds.put((IBond) b_new, -fiap[i]); 
					//System.out.println("new p: " + all_bonds.get((IBond) b_new)); 
				}
				else { 
					//System.out.println("old p: " + old_p); 
					all_bonds.put((IBond) b_new, (Float)(old_p-fiap[i])); 
					//System.out.println("new p: " + all_bonds.get((IBond) b_new)); 
				}
				//System.out.println("\tiab: " + all_bonds.size());
			}
			i++;
		}
		
		i = 0;
		for (String as : active_smarts) { 
			List ab = getBondsFromSmarts(as); 
			//System.out.println(as + " " + i + "(" + fap[i] + ")");
			for (Object b_new : ab) {
				Float old_p = all_bonds.get((IBond) b_new);
				if (old_p == null) { 
					//System.out.println("null"); 
					all_bonds.put((IBond) b_new, fap[i]); 
					//System.out.println("new p: " + all_bonds.get((IBond) b_new)); 
				}
				else { 
					//System.out.println("old p: " + old_p); 
					all_bonds.put((IBond) b_new, (Float)(old_p+fap[i])); 
					//System.out.println("new p: " + all_bonds.get((IBond) b_new)); 
				}
				//System.out.println("\tab: " + all_bonds.size());
			}
			i++;
		}

		for (String us : unknown_smarts) { 
			List ub = getBondsFromSmarts(us); 
			for (Object cur_b : ub) {
				Color c = Color.yellow;
				r2dm.getColorHash().put((IBond) cur_b, c);
			}
		}
		
		
		Float max_p = new Float(0.0);
		Float min_p = new Float(0.0);

		for (Float cur_p : all_bonds.values()) {
			if (cur_p > max_p) max_p = cur_p;
			if (cur_p < min_p) min_p = cur_p;
		}
		//System.out.println("max_p: " + max_p);
		//System.out.println("min_p: " + min_p);

		for (Object cur_b : all_bonds.keySet()) {
			Color c = Color.black;
			Float cur_p = all_bonds.get((IBond) cur_b);
			float dist = Math.abs(max_p.floatValue() - min_p.floatValue());
			if (cur_p < 0) {
				//float alpha = (float) 0.3 + ((cur_p.floatValue())/min_p.floatValue() * (float)0.7);
				float alpha = (float) 0.3 + ((cur_p.floatValue())/dist * (float)0.7 * (float)-1.0);
				c = new Color((float) 0.0, (float) 1.0, (float) 0.0, alpha);	// green (deact.)
			}
			if (cur_p > 0) {
				//float alpha = (float) 0.3 + ((cur_p.floatValue())/max_p.floatValue() * (float)0.7);
				float alpha = (float) 0.3 + ((cur_p.floatValue())/dist * (float)0.7);
				c = new Color((float) 1.0, (float) 0.0, (float) 0.0, alpha);	// red   (act.)
			}
			r2dm.getColorHash().put((IBond) cur_b, c);
		}
	


		arrangeAndPaintImage();

		return image;

  }

  public BufferedImage displaySubstructure(String smiles , String[] active_smarts, String[] inactive_smarts, String[] unknown_smarts) {

		coordinateSmiles(smiles);
		setDisplayOptions();
		matchSmarts(unknown_smarts, Color.yellow);
		matchSmarts(inactive_smarts, Color.green);
		matchSmarts(active_smarts, Color.red);
		arrangeAndPaintImage();

		return image;

  }

	private void coordinateSmiles(String smiles) {
		try {
			// parse smiles
			sp = new SmilesParser(DefaultChemObjectBuilder.getInstance());
			molecule = sp.parseSmiles(smiles);
			moleculeSet = ConnectivityChecker.partitionIntoMolecules(molecule);
			sdg = new StructureDiagramGenerator();
			sdg.setUseTemplates(true);

			// calculate coordinates for each disconnected structure
			IMolecule[] coordinated_mols = new IMolecule[moleculeSet.getMoleculeCount()];
			for (int i = 0; i < moleculeSet.getMoleculeCount(); i++) {
			// generate coordinates
				sdg.setMolecule((IMolecule) moleculeSet.getMolecule(i));
				sdg.generateCoordinates();
				coordinated_mols[i] = sdg.getMolecule();
			}
			moleculeSet.setMolecules(coordinated_mols);
		}
		catch (Exception exc) {
				exc.printStackTrace();
		}
	}

/*
	private void matchSmartsHash(HashMap[] smarts, Color color) {
		try {
			matches = new AtomContainer();
			// map smarts
			for (HashMap s : smarts) {
				List<String> smartsList = new ArrayList<String>();
				smartsList.addAll(s.keySet());
				Iterator<String> iter = smartsList.iterator();
				String key = "";
				while (iter.hasNext()) {
					key = iter.next();
				}
				querytool = new SMARTSQueryTool(key);
				idlist = new Vector<Integer>();
				boolean status = querytool.matches(molecule);
				if (status) {
					mappings = querytool.getMatchingAtoms();
					int nmatch = querytool.countMatches();
					for (int i = 0; i < nmatch; i++) {
						List atomIndices = (List) mappings.get(i);
						for (int n = 0; n < atomIndices.size(); n++) {
							Integer atomID = (Integer) atomIndices.get(n);
							idlist.add(atomID);
						}
					}
				}

				// get a unique list of bond ID's and add them to an AtomContainer
				HashSet<Integer> hs = new HashSet<Integer>(idlist);
				for (Integer h : hs) {
					IAtom a = molecule.getAtom(h);
					//r2dm.getColorHash().put(a, color);
					List bond_list = molecule.getConnectedBondsList(a);
					for (int i = 0; i < bond_list.size(); i++) {
						IBond b = (IBond) bond_list.get(i);
						Integer connectedNr = molecule.getAtomNumber(b.getConnectedAtom(a));
						if (hs.contains(connectedNr)) r2dm.getColorHash().put(b, color);
					}
				}
			}

		} catch (Exception exc) {
				exc.printStackTrace();
		}

	}
*/


	private List getBondsFromSmarts(String s) {
			if (moleculeSet.getMoleculeCount() == 1) {
				IAtomContainer mol = moleculeSet.getMolecule(0);
				return getBondsFromSmartsMol(s, mol);
			}
				
			else {
				List fully_connected_bonds = new ArrayList();
				for (int i = 0; i < moleculeSet.getMoleculeCount(); i++) {
					IAtomContainer mol = moleculeSet.getMolecule(i);
					fully_connected_bonds.addAll(getBondsFromSmartsMol(s,mol));
				}
				return fully_connected_bonds;
			}

	}

	private List getBondsFromSmartsMol(String s, IAtomContainer mol) {

		List fully_connected_bonds = new ArrayList();

		try {
			matches = new AtomContainer();
			// map smarts
			querytool = new SMARTSQueryTool(s);
			idlist = new Vector<Integer>();
			boolean status = querytool.matches(mol);
			if (status) {
				mappings = querytool.getMatchingAtoms();
				int nmatch = querytool.countMatches();
				for (int i = 0; i < nmatch; i++) {
					List atomIndices = (List) mappings.get(i);
					for (int n = 0; n < atomIndices.size(); n++) {
						Integer atomID = (Integer) atomIndices.get(n);
						idlist.add(atomID);
					}
				}
			}

			// get a unique list of bond ID's and add them to an AtomContainer
			HashSet<Integer> hs = new HashSet<Integer>(idlist);
			for (Integer a : hs) {
				IAtom aa = mol.getAtom(a);
				List aa_ori_bonds = mol.getConnectedBondsList(aa);
				List aa_copy_bonds = mol.getConnectedBondsList(aa);
				for (Object aab : aa_copy_bonds) {
					boolean bond_in_smarts = false;
					for (Integer b : hs) {
						IAtom bb = mol.getAtom(b);
						List bb_bonds = mol.getConnectedBondsList(bb);
						for (Object bbb : bb_bonds) {
							if ((IBond) aab == (IBond) bbb) {
								bond_in_smarts = true;
								break;
							}
						}
						if (bond_in_smarts) break;
					}
					if (!bond_in_smarts) aa_ori_bonds.remove(aab);
				}
				
				// remember good bonds
				for (Object b_new : aa_ori_bonds) {
					boolean found = false;
					for (Object b_old : fully_connected_bonds) {
						if (((IBond) b_old) == ((IBond) b_new)) {
							found = true;
							break;
						}
					}
					if (!found) fully_connected_bonds.add(b_new);
				}
			}

		} 

		catch (Exception exc) {
			exc.printStackTrace();
		}

		return(fully_connected_bonds);

	}


	private void matchSmarts(String[] smarts, Color color) {
		try {
			matches = new AtomContainer();
			// map smarts
			for (String s : smarts) {
				querytool = new SMARTSQueryTool(s);
				idlist = new Vector<Integer>();
				boolean status = querytool.matches(molecule);
				if (status) {
					mappings = querytool.getMatchingAtoms();
					int nmatch = querytool.countMatches();
					for (int i = 0; i < nmatch; i++) {
						List atomIndices = (List) mappings.get(i);
						for (int n = 0; n < atomIndices.size(); n++) {
							Integer atomID = (Integer) atomIndices.get(n);
							idlist.add(atomID);
						}
					}
				}

				// get a unique list of bond ID's and add them to an AtomContainer
				HashSet<Integer> hs = new HashSet<Integer>(idlist);
				for (Integer h : hs) {
					IAtom a = molecule.getAtom(h);
					List bond_list = molecule.getConnectedBondsList(a);
					for (int i = 0; i < bond_list.size(); i++) {
						IBond b = (IBond) bond_list.get(i);
						Integer connectedNr = molecule.getAtomNumber(b.getConnectedAtom(a));
						if (hs.contains(connectedNr)) r2dm.getColorHash().put(b, color);
					}
				}
			}

		} catch (Exception exc) {
				exc.printStackTrace();
		}

	}

	private void setDisplayOptions() {
		try {

			r2dm = new Renderer2DModel();
			// set display options
			size = 125;  
			r2dm.setDrawNumbers(false);
			r2dm.setUseAntiAliasing(true);
			r2dm.setShowImplicitHydrogens(true);
			r2dm.setShowAromaticityInCDKStyle(true);
			r2dm.setColorAtomsByType(true);
			r2dm.setShowAtomTypeNames(true);
			r2dm.setBackColor(Color.white);
			r2dm.setFont(new Font("SansSerif", Font.BOLD, 10));
			r2dm.setBackgroundDimension(new Dimension(size,size));
			//r2dm.setIsCompact(false);
			r2dm.setBondDistance(2*r2dm.getBondWidth());

		} catch (Exception exc) {
				exc.printStackTrace();
		}

	}

	private void arrangeAndPaintImage() {
		try {

			image = new BufferedImage(size, size, BufferedImage.TYPE_INT_RGB);

			// Draw myImage on the current graphics context
			Graphics g = image.getGraphics();
			g.setColor(Color.white);
			g.fillRect(0,0,size,size);

			renderer = new Renderer2D(r2dm);
			
			// arrange image
			if (moleculeSet.getMoleculeCount() == 1) {	// center single structure

				IAtomContainer mol = moleculeSet.getMolecule(0);
				GeometryTools.translateAllPositive(mol, r2dm.getRenderingCoordinates());
				GeometryTools.scaleMolecule(mol, r2dm.getBackgroundDimension(), 0.8, r2dm.getRenderingCoordinates());
				GeometryTools.center(mol, r2dm.getBackgroundDimension(), r2dm.getRenderingCoordinates());

			}

			else { // disconnected structure

				int nr_structures = moleculeSet.getMoleculeCount();

				int nrbigmols = 0;
				boolean onlybigmols = false;
				for (int i = 0; i < nr_structures; i++) {
					// get nr of big mols
					if (moleculeSet.getMolecule(i).getAtomCount()>5) {
						nrbigmols += 1;
					}
					// get whether only big mols
					if (nr_structures == nrbigmols) onlybigmols = true;
				}

				int j=0;
				int k=0;
				for (int i = 0; i < nr_structures; i++) {

					IAtomContainer mol = moleculeSet.getMolecule(i);
					GeometryTools.translateAllPositive(mol, r2dm.getRenderingCoordinates());

					if (onlybigmols) { 
						// make it small
						GeometryTools.scaleMolecule(mol, 
									    r2dm.getBackgroundDimension(), 
									    2.0/(nr_structures+1), 
									    r2dm.getRenderingCoordinates());
						// display 
						int d1 = (int)(size/nr_structures + i*(2*size)/nr_structures);
						int d2 = size;
						GeometryTools.center(mol,new Dimension(d1,d2), r2dm.getRenderingCoordinates());

					}

					else {

						if (moleculeSet.getMolecule(i).getAtomCount()>5) {
							double sf = 1.5;
						        if (nrbigmols == 1) sf = 1.0;
							GeometryTools.scaleMolecule(mol,
										    new Dimension(3*size/5,size),
									    	    (double)(sf/nrbigmols), 
										    r2dm.getRenderingCoordinates());
							int d1 = size;
							int big_structure_height = size/nrbigmols;
							System.out.println("NRBIGMOLS: " + nrbigmols);
							int d2 = (int)(2*j*big_structure_height) + (int)(big_structure_height);
							GeometryTools.center(mol,  new Dimension(d1,d2), r2dm.getRenderingCoordinates());
							j += 1;
						}


						else { // usually small structures like counter ions, crystal water, ...
							// make it small
							GeometryTools.scaleMolecule(mol,
										    r2dm.getBackgroundDimension(), 
										    0.2, 
										    r2dm.getRenderingCoordinates());
							// display 
							int d1 = size+3*size/5;
							int small_structure_height = size/(nr_structures-nrbigmols);
							int d2 = (int)(2*k*small_structure_height)+(int)(small_structure_height);
							GeometryTools.center(mol,new Dimension(d1,d2), r2dm.getRenderingCoordinates());
							k += 1;
						}
					}
				}
			}
			renderer.paintMoleculeSet(moleculeSet, (Graphics2D) g, true);

		} catch (Exception exc) {
				exc.printStackTrace();
		}
	}
}
