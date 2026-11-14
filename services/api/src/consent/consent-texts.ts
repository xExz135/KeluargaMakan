/**
 * Consent texts served by `GET /v1/consent-texts/{purpose}` (ACC-08, SET-03,
 * SET-10). The client shows these and sends the version back with the
 * decision; every consent record stores that version, so the final, legally
 * reviewed texts are a content swap with a new version (QUESTIONS #23, T-090).
 *
 * DRAFT: needs legal review. The wording comes from the ux-designer's copy
 * deck (`consent.rules.*`, `consent.full.*`, `family.guardian.*`,
 * `consent.child.note`), all marked DRAFT there. `isDraft` stays true until
 * legal approves a version. Agents do not write legal text: the "full text"
 * section is the copy deck's placeholder for the legal team.
 */

export type ConsentPurpose = "health_data" | "guardian_confirmation";
export type ConsentLanguage = "id" | "en";

export interface ConsentTextSection {
  readonly heading: string;
  readonly body: string;
}

export interface ConsentTextContent {
  readonly purpose: ConsentPurpose;
  readonly version: string;
  readonly effectiveDate: string;
  readonly isDraft: boolean;
  readonly languages: Readonly<
    Record<
      ConsentLanguage,
      { readonly title: string; readonly sections: readonly ConsentTextSection[] }
    >
  >;
}

const HEALTH_DATA: ConsentTextContent = {
  purpose: "health_data",
  version: "health-data-draft-1",
  effectiveDate: "2026-11-12",
  isDraft: true,
  languages: {
    id: {
      title: "Persetujuan menyimpan aturan makan",
      sections: [
        {
          heading: "Yang disimpan",
          body: "Alergi, aturan makan (seperti halal) dan pantangan dari dokter yang Anda pilih.",
        },
        {
          heading: "Untuk apa",
          body: "Supaya Cek Aman bisa memeriksa setiap resep untuk anggota keluarga ini.",
        },
        {
          heading: "Di mana",
          body: "Di server KeluargaMakan, dikunci dengan kunci terpisah. Tidak dikirim bersama nama ke layanan AI.",
        },
        {
          heading: "Menarik izin",
          body: "Anda bisa menarik izin kapan saja di Pengaturan. Aturan makan lalu berhenti dipakai dan dihapus.",
        },
        {
          heading: "Penjelasan lengkap",
          body: "[DRAFT: teks lengkap dari tim legal. Harus mencakup: data apa, tujuan, dasar pemrosesan menurut UU PDP, lokasi penyimpanan, siapa yang bisa mengakses, berapa lama disimpan, hak menarik izin dan akibatnya, kontak.]",
        },
      ],
    },
    en: {
      title: "Consent to save food rules",
      sections: [
        {
          heading: "What we save",
          body: "The allergies, food rules (like halal) and doctor's restrictions you picked.",
        },
        {
          heading: "Why",
          body: "So Cek Aman can check every recipe for this family member.",
        },
        {
          heading: "Where",
          body: "On KeluargaMakan's servers, locked with a separate key. Never sent with a name to AI services.",
        },
        {
          heading: "Withdrawing",
          body: "You can withdraw this any time in Settings. The food rules then stop being used and are deleted.",
        },
        {
          heading: "Full explanation",
          body: "[DRAFT: full text from legal. Must cover: what data, purpose, legal basis under UU PDP, storage location, who can access it, retention, the right to withdraw and its effect, contact.]",
        },
      ],
    },
  },
};

const GUARDIAN_CONFIRMATION: ConsentTextContent = {
  purpose: "guardian_confirmation",
  version: "guardian-confirmation-draft-1",
  effectiveDate: "2026-11-12",
  isDraft: true,
  languages: {
    id: {
      title: "Konfirmasi orang tua atau wali",
      sections: [
        {
          heading: "Data anak",
          body: "Data anak di bawah 18 tahun kami jaga lebih ketat. Data kesehatan anak tidak disimpan kecuali Anda izinkan, dan tidak pernah dipakai untuk pemasaran.",
        },
        {
          heading: "Konfirmasi",
          body: "Saya orang tua atau wali anak ini, dan saya yang mengatur data anak ini di aplikasi ini.",
        },
      ],
    },
    en: {
      title: "Parent or guardian confirmation",
      sections: [
        {
          heading: "Children's data",
          body: "We protect data about children under 18 more strictly. A child's health data is not saved unless you allow it, and it's never used for marketing.",
        },
        {
          heading: "Confirmation",
          body: "I am this child's parent or guardian, and I manage this child's data in this app.",
        },
      ],
    },
  },
};

/**
 * SET-10, QUESTIONS #62: the health-data text a manager accepts for a child
 * (infant, child or teen) as parent or guardian. Same sections as the adult
 * text, plus the copy deck's `consent.member.childNote` and
 * `consent.child.note` (names removed). DRAFT: needs legal review.
 */
const HEALTH_DATA_CHILD: ConsentTextContent = {
  purpose: "health_data",
  version: "health-data-child-draft-1",
  effectiveDate: "2026-11-12",
  isDraft: true,
  languages: {
    id: {
      title: HEALTH_DATA.languages.id.title,
      sections: [
        {
          heading: "Untuk anak",
          body: "Anggota ini masih anak-anak. Sebagai orang tua atau wali, Anda yang memberi izin ini. Data anak dijaga lebih ketat dan tidak pernah dipakai untuk pemasaran.",
        },
        ...HEALTH_DATA.languages.id.sections,
      ],
    },
    en: {
      title: HEALTH_DATA.languages.en.title,
      sections: [
        {
          heading: "For a child",
          body: "This family member is a child. As their parent or guardian, you give this consent. Children's data gets extra protection and is never used for marketing.",
        },
        ...HEALTH_DATA.languages.en.sections,
      ],
    },
  },
};

export type ConsentAudience = "adult" | "child";

export const CONSENT_TEXTS: Readonly<Record<ConsentPurpose, ConsentTextContent>> = Object.freeze({
  health_data: HEALTH_DATA,
  guardian_confirmation: GUARDIAN_CONFIRMATION,
});

/** The current health-data text per audience. */
export const HEALTH_DATA_TEXTS: Readonly<Record<ConsentAudience, ConsentTextContent>> =
  Object.freeze({ adult: HEALTH_DATA, child: HEALTH_DATA_CHILD });

/**
 * Every health-data text version ever served, with its audience. When legal
 * replaces a text, the old version stays here so earlier consents keep their
 * audience. A version not listed belongs to no audience, so its consent does
 * not allow new health data (fail closed).
 */
const HEALTH_DATA_VERSION_AUDIENCE: ReadonlyMap<string, ConsentAudience> = new Map([
  [HEALTH_DATA.version, "adult"],
  [HEALTH_DATA_CHILD.version, "child"],
]);

export function audienceOfHealthVersion(version: string | null): ConsentAudience | null {
  return version === null ? null : (HEALTH_DATA_VERSION_AUDIENCE.get(version) ?? null);
}

export function audienceFor(isChild: boolean): ConsentAudience {
  return isChild ? "child" : "adult";
}

/** The text served for a purpose; `audience` selects the health-data version. */
export function consentTextFor(
  purpose: ConsentPurpose,
  audience: ConsentAudience = "adult",
): ConsentTextContent {
  return purpose === "health_data" ? HEALTH_DATA_TEXTS[audience] : CONSENT_TEXTS[purpose];
}

/** The current text version for a purpose. A decision must quote it (409 `consent_text_outdated`). */
export function currentConsentVersion(
  purpose: ConsentPurpose,
  audience: ConsentAudience = "adult",
): string {
  return consentTextFor(purpose, audience).version;
}
