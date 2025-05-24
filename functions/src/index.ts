import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();

export const onOfferStatusUpdate = functions.firestore
    .document('sell_offers/{offerId}')
    .onUpdate(async (change, context) => {
        const newData = change.after.data();
        const previousData = change.before.data();

        // Only proceed if status changed to 'accepted'
        if (previousData.status !== 'accepted' && newData.status === 'accepted') {
            const userId = newData.userId;
            const weightToDeduct = newData.kilograms;
            const material = newData.material;
            const offerId = context.params.offerId;

            try {
                // Get all bins owned by the user
                const binsSnapshot = await admin.firestore()
                    .collection('registered_bins')
                    .where('owners', 'array-contains', userId)
                    .get();

                if (binsSnapshot.empty) {
                    console.error(`No bins found for user ${userId}`);
                    return;
                }

                // Calculate total weight available across all bins
                let totalWeight = 0;
                const bins = binsSnapshot.docs.map(doc => {
                    const data = doc.data();
                    const binWeight = material.toLowerCase() === 'plastic' 
                        ? (data.plastic_total_weight || 0) 
                        : (data.metal_total_weight || 0);
                    totalWeight += binWeight;
                    return {
                        ref: doc.ref,
                        weight: binWeight,
                        data: data
                    };
                });

                // Verify if there's enough weight to deduct
                if (totalWeight < weightToDeduct) {
                    console.error(`Not enough weight available. Required: ${weightToDeduct}, Available: ${totalWeight}`);
                    // Revert the offer status to 'pending'
                    await change.after.ref.update({
                        status: 'pending',
                        statusMessage: 'Insufficient stock available'
                    });
                    return;
                }

                // Deduct weight proportionally from each bin
                const batch = admin.firestore().batch();
                
                for (const bin of bins) {
                    if (bin.weight > 0) {
                        const proportion = bin.weight / totalWeight;
                        const weightToDeductFromBin = weightToDeduct * proportion;
                        
                        const updateField = material.toLowerCase() === 'plastic' 
                            ? 'plastic_total_weight' 
                            : 'metal_total_weight';
                        
                        const currentWeight = material.toLowerCase() === 'plastic'
                            ? bin.data.plastic_total_weight
                            : bin.data.metal_total_weight;

                        batch.update(bin.ref, {
                            [updateField]: currentWeight - weightToDeductFromBin,
                            lastUpdated: admin.firestore.FieldValue.serverTimestamp()
                        });
                    }
                }

                // Create a weight deduction record
                const deductionRef = admin.firestore()
                    .collection('weight_deductions')
                    .doc();
                
                batch.set(deductionRef, {
                    offerId: offerId,
                    userId: userId,
                    material: material,
                    totalWeightDeducted: weightToDeduct,
                    timestamp: admin.firestore.FieldValue.serverTimestamp(),
                    bins: bins.map(bin => ({
                        binId: bin.ref.id,
                        weightBefore: bin.weight,
                        deductedWeight: bin.weight > 0 
                            ? (weightToDeduct * (bin.weight / totalWeight))
                            : 0
                    }))
                });

                // Commit all the updates
                await batch.commit();

                console.log(`Successfully deducted ${weightToDeduct}kg of ${material} for offer ${offerId}`);
            } catch (error) {
                console.error('Error processing weight deduction:', error);
                // Revert the offer status
                await change.after.ref.update({
                    status: 'pending',
                    statusMessage: 'Error processing weight deduction'
                });
            }
        }
    }); 