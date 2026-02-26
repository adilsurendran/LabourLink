import vader from "vader-sentiment";

function compoundToRating(compound) {
  return ((compound + 1) / 2) * 4 + 1;
}

export function calculateHybridRating(userRating, reviewText) {
  const intensity =
    vader.SentimentIntensityAnalyzer.polarity_scores(reviewText || "");

  const compound = intensity.compound;
  const sentimentRating = compoundToRating(compound);

  const difference = Math.abs(userRating - sentimentRating);

  let finalRating;
  let isFlagged = false;

  if (difference > 2) {
    finalRating = (userRating * 0.85) + (sentimentRating * 0.15);
    isFlagged = true;
  } else {
    finalRating = (userRating * 0.7) + (sentimentRating * 0.3);
  }

  return {
    compound: Number(compound.toFixed(3)),
    sentimentRating: Number(sentimentRating.toFixed(2)),
    finalRating: Number(finalRating.toFixed(2)),
    isFlagged,
  };
}