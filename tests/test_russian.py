"""Russian locale: persistence, placeholders, localized card data and QML coverage."""
import json
import re
from pathlib import Path
from string import Formatter
from src.cairn import cards_db, cards_fetch, i18n
from src.cairn.config import Config


def test_russian_survives_config_reload(tmp_path):
    p = tmp_path / 'config.json'
    Config(language='ru').save(p)
    assert Config.load(p).language == 'ru'
    assert i18n.locale_of('ru') == 'ruRU'
    assert i18n.class_name('DEATHKNIGHT', 'ru') == 'Рыцарь смерти'
    assert i18n.t('in_deck', 'ru', n=28) == '28 в колоде'
    assert i18n.class_name('CUSTOM', 'ru') == 'CUSTOM'


def test_russian_format_fields():
    fields = lambda s: {name for _, name, _, _ in Formatter().parse(s) if name} - {'s'}
    for row in i18n._STRINGS.values():
        assert fields(row[3]) == fields(row[0])


def test_russian_card_names_and_text_and_missing_card_fallback(monkeypatch, tmp_path):
    names, texts, fr = [tmp_path / name for name in ('ru.json', 'text.ru.json', 'text.fr.json')]
    names.write_text(json.dumps([{'id': 'X', 'name': 'Монетка'}]), encoding='utf-8')
    texts.write_text(json.dumps({'X': 'Получите 1 кристалл маны.'}), encoding='utf-8')
    fr.write_text(json.dumps({'Y': 'Texte de secours'}), encoding='utf-8')
    monkeypatch.setattr(cards_db, 'CARDS_JSON_RU', names)
    monkeypatch.setattr(cards_db, 'CARDS_TEXT_RU', texts)
    monkeypatch.setattr(cards_db, 'CARDS_TEXT', fr)
    db = cards_db.CardsDb([{'id': 'X', 'name': 'La pièce'}, {'id': 'Y', 'name': 'Repli'}])
    assert db.localized_name('X', 'ru') == 'Монетка'
    assert db.text('X', 'ru') == 'Получите 1 кристалл маны.'
    assert db.localized_source_name('La pièce', 'ru') == 'Монетка'
    assert db.localized_source_name('Unknown source', 'ru') == 'Unknown source'
    assert db.localized_name('Y', 'ru') == 'Repli'
    assert db.text('Y', 'ru') == 'Texte de secours'
    assert cards_fetch.slim([{'id': 'X', 'name': 'Монетка', 'cost': 0, 'type': 'SPELL'}], 'ruRU') == [{'id': 'X', 'name': 'Монетка'}]


def test_qml_language_arrays_have_four_columns():
    string = r'"(?:[^"\\]|\\.)*"'
    expression = rf'{string}(?:\s*\+\s*{string})*'
    pattern = re.compile(rf'\[\s*({expression}(?:\s*,\s*{expression})+)\s*\]\s*\[\s*(?:tracker\.langIndex|langCase\.index)\s*\]')
    qml = Path(__file__).resolve().parents[1] / 'src/cairn/ui/qml'
    count = 0
    for p in qml.glob('*.qml'):
        for match in pattern.finditer(p.read_text()):
            columns = re.findall(rf'(?:^|,)\s*({expression})', match[1])
            assert len(columns) == len(i18n.LANGS), (p.name, columns)
            count += 1
    assert count > 25
