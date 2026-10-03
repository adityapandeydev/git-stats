import React from 'react'
import LanguagesCard from './LanguagesCard'
import StreakCard from './StreakCard'
import StatsCard from './StatsCard'
import RhythmCard from './RhythmCard'
import RadarCard from './RadarCard'
import VelocityCard from './VelocityCard'
import MilestonesCard from './MilestonesCard'

export default function CardRenderer({ card, themeId, userData }) {
  switch (card.id) {
    case 'languages':
      return (
        <LanguagesCard
          width={card.width}
          height={card.height}
          themeId={themeId}
          langsCount={card.langsCount}
          userData={userData}
        />
      )
    case 'streak':
      return (
        <StreakCard
          width={card.width}
          height={card.height}
          themeId={themeId}
          sparkline={card.sparkline !== false}
          userData={userData}
        />
      )
    case 'stats':
      return (
        <StatsCard
          width={card.width}
          height={card.height}
          themeId={themeId}
          userData={userData}
        />
      )
    case 'rhythm':
      return (
        <RhythmCard
          width={card.width}
          height={card.height}
          themeId={themeId}
        />
      )
    case 'radar':
      return (
        <RadarCard
          width={card.width}
          height={card.height}
          themeId={themeId}
        />
      )
    case 'velocity':
      return (
        <VelocityCard
          width={card.width}
          height={card.height}
          themeId={themeId}
        />
      )
    case 'milestones':
      return (
        <MilestonesCard
          width={card.width}
          height={card.height}
          themeId={themeId}
        />
      )
    default:
      return null
  }
}
